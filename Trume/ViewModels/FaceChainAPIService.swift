//
//  FaceChainAPIService.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import Foundation
import OSLog
import UIKit

enum FaceChainProgressCheckpoint {
    case trainingArchiveUploaded
    case finetuneJobCreated
    case trainingResourceReady
}

typealias FaceChainProgressHandler = (FaceChainProgressCheckpoint) -> Void

class FaceChainAPIService {
    // MARK: - Configuration
    // 参考官方文档：https://help.aliyun.com/zh/model-studio/facechain-quick-start
    private let generationEndpoint = "https://dashscope.aliyuncs.com/api/v1/services/aigc/album/gen_potrait"
    private let taskEndpoint = "https://dashscope.aliyuncs.com/api/v1/tasks"
    private let fileUploadEndpoint = "https://dashscope.aliyuncs.com/api/v1/files"
    private let finetuneEndpoint = "https://dashscope.aliyuncs.com/api/v1/fine-tunes"
    //private let apiKey = "sk-00d2dfc333c54979968510ed81ca0f1c"
    private let apiKey = "sk-978058781d7f42d387d6ce67ce73780b"
    private let session: URLSession
    private let logger = Logger(subsystem: "com.trume.facechain", category: "FaceChainAPIService")
    
    // 最多轮询任务结果次数（官方示例中每 10 秒轮询一次）
    private var maxPollingAttempts = 18
    private var pollingInterval: TimeInterval = 5.0
    private var maxTrainingPollingAttempts = 36
    private var trainingPollingInterval: TimeInterval = 10.0
    
    init(session: URLSession? = nil) {
        // 创建一个自定义配置的 URLSession，避免后台任务相关的问题
        if let session = session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.allowsCellularAccess = true
            configuration.timeoutIntervalForRequest = 60
            configuration.timeoutIntervalForResource = 300
            configuration.waitsForConnectivity = false
            // 明确指定不使用后台会话，避免 RBSAssertion 错误
            self.session = URLSession(configuration: configuration)
        }
    }
    
    // 更新配置参数
    func updateConfiguration(
        maxTrainingPollingAttempts: Int,
        trainingPollingInterval: TimeInterval,
        maxPollingAttempts: Int,
        pollingInterval: TimeInterval
    ) {
        self.maxTrainingPollingAttempts = maxTrainingPollingAttempts
        self.trainingPollingInterval = trainingPollingInterval
        self.maxPollingAttempts = maxPollingAttempts
        self.pollingInterval = pollingInterval
    }
    
    // MARK: - Generate Portraits
    /// 使用FaceChain trainfree模式，根据预设模板生成写真图片
    /// - Parameters:
    ///   - photos: 用户选择的人物照片数组
    ///   - templates: 模板列表（按顺序）
    ///   - completion: 完成回调，返回按模板顺序排列的图片URL数组
    func generatePortraits(
        with photos: [SelectedPhoto],
        templates: [TemplateItem],
        progressHandler: FaceChainProgressHandler? = nil,
        completion: @escaping (Result<[String], FaceChainError>) -> Void
    ) {
        logger.info("🚀 Starting portrait generation. photos=\(photos.count), templates=\(templates.count)")
        
        guard !photos.isEmpty else {
            logger.error("❌ Generation aborted. Reason=No photos provided.")
            completion(.failure(.invalidInput("At least one photo is required")))
            return
        }
        
        guard !templates.isEmpty else {
            logger.error("❌ Generation aborted. Reason=No templates provided.")
            completion(.failure(.invalidInput("No templates available")))
            return
        }
        
        guard photos.allSatisfy({ $0.imageData != nil }) else {
            logger.error("❌ Generation aborted. Reason=One or more photos missing image data.")
            completion(.failure(.invalidInput("Selected photos must include image data.")))
            return
        }
        
        prepareTrainingResource(with: photos, progressHandler: progressHandler) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let resourceId):
                self.logger.info("🎓 Training resource ready. resourceId=\(resourceId)")
                progressHandler?(.trainingResourceReady)
                self.generatePortraits(resourceId: resourceId, templates: templates, completion: completion)
            case .failure(let error):
                self.logger.error("❌ Training resource preparation failed. error=\(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func generatePortraits(
        resourceId: String,
        templates: [TemplateItem],
        completion: @escaping (Result<[String], FaceChainError>) -> Void
    ) {
        let templateCount = templates.count
        var results = Array(repeating: [String](), count: templateCount)
        var errors: [FaceChainError] = []
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "com.trume.facechain.results", attributes: .concurrent)
        
        for (index, template) in templates.enumerated() {
            dispatchGroup.enter()
            logger.debug("🎯 Submitting template index \(index) name=\(template.name) with resourceId=\(resourceId)")
            
            invokeGenerationAPI(
                resourceId: resourceId,
                template: template
            ) { result in
                queue.async(flags: .barrier) {
                    switch result {
                    case .success(let imageUrls):
                        results[index] = imageUrls
                    case .failure(let error):
                        errors.append(error)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let flattenedResults = results.flatMap { $0 }.filter { !$0.isEmpty }
            let successCount = results.filter { !$0.isEmpty }.count
            
            // 如果有错误，显示详细的错误信息
            if !errors.isEmpty {
                let errorMessages = errors.map { $0.localizedDescription }.joined(separator: "; ")
                if successCount == 0 {
                    // 所有模板都失败了
                    self.logger.error("❌ Generation failed for all templates. errors=\(errorMessages)")
                    completion(.failure(.apiError("Generation failed for all templates: \(errorMessages)")))
                } else {
                    // 部分失败
                    self.logger.error("❌ Generation partially failed. succeeded=\(successCount)/\(templateCount), errors=\(errorMessages)")
                    completion(.failure(.apiError("Generation partially failed (\(successCount)/\(templateCount) succeeded): \(errorMessages)")))
                }
                return
            }
            
            if flattenedResults.isEmpty {
                self.logger.error("❌ Generation completed but returned no images.")
                completion(.failure(.apiError("Generation completed but returned no images")))
                return
            }
            
            self.logger.info("✅ Generation completed for all templates. totalImages=\(flattenedResults.count)")
            completion(.success(flattenedResults))
        }
    }
    
    private func invokeGenerationAPI(
        resourceId: String,
        template: TemplateItem,
        completion: @escaping (Result<[String], FaceChainError>) -> Void
    ) {
        guard let url = URL(string: generationEndpoint) else {
            logger.error("❌ Generation endpoint invalid.")
            completion(.failure(.invalidInput("Generation endpoint invalid")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer ".appending(apiKey), forHTTPHeaderField: "Authorization")
        request.setValue("enable", forHTTPHeaderField: "X-DashScope-Async")
        
        let payload: [String: Any] = [
            "model": "facechain-generation",
            // "input": [
            //     "template_url": template.image_url
            // ],
            "parameters": [
                // "style": "portrait_url_template",
                "style": template.styleCode,
                // "style": "f_lightportray_female",
                "size": "768*1024",
                "n": 4
            ],
            "resources": [
                [
                    "resource_id": resourceId,
                    "resource_type": "facelora"
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            logger.error("❌ Failed to encode request payload. template=\(template.name)")
            completion(.failure(.invalidInput("Failed to encode request payload")))
            return
        }
        
        logger.info("🛰️ Invoking generation API. template=\(template.name), style=\(template.styleCode), resourceId=\(resourceId)")
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            
            if let error = error {
                self.logger.error("❌ Generation request error. template=\(template.name), message=\(error.localizedDescription)")
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                self.logger.error("❌ Generation request failed status. template=\(template.name), status=\((response as? HTTPURLResponse)?.statusCode ?? -1)")
                completion(.failure(.apiError("Generation request failed")))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let output = json["output"] as? [String: Any] {
                        let urls = self.extractImageURLs(from: output)
                        
                        if !urls.isEmpty {
                            let reportedCount = self.extractImageCount(from: json, fallback: urls.count)
                            self.logger.info("✅ Generation returned \(urls.count) image URLs. template=\(template.name), reported=\(reportedCount)")
                            completion(.success(urls))
                        } else if let taskId = output["task_id"] as? String {
                            self.logger.info("⏳ Generation queued asynchronously. taskId=\(taskId), template=\(template.name)")
                            self.pollGenerationResult(taskId: taskId, attempts: 0, completion: completion)
                        } else if let imageUrl = output["image_url"] as? String {
                            self.logger.info("✅ Generation succeeded with direct image_url. template=\(template.name)")
                            completion(.success([imageUrl]))
                        } else {
                            self.logger.error("❌ Unexpected generation response structure. template=\(template.name)")
                            completion(.failure(.apiError("Unexpected generation response format")))
                        }
                    } else {
                        let urls = self.extractImageURLs(from: json)
                        if !urls.isEmpty {
                            let reportedCount = self.extractImageCount(from: json, fallback: urls.count)
                            self.logger.info("✅ Generation returned \(urls.count) image URLs at root. template=\(template.name), reported=\(reportedCount)")
                            completion(.success(urls))
                        } else if let imageUrl = json["image_url"] as? String {
                            self.logger.info("✅ Generation succeeded with root image_url. template=\(template.name)")
                            completion(.success([imageUrl]))
                        } else {
                            self.logger.error("❌ Unable to parse generation response. template=\(template.name)")
                            completion(.failure(.apiError("Unable to parse generation response")))
                        }
                    }
                    
                    if let usage = json["usage"] as? [String: Any],
                       let imageCount = usage["image_count"] as? Int {
                        self.logger.debug("📊 Generation usage metrics. image_count=\(imageCount)")
                    } else {
                        self.logger.debug("ℹ️ Generation usage metrics not present in response.")
                    }
                } else {
                    self.logger.error("❌ Invalid JSON response. template=\(template.name)")
                    completion(.failure(.apiError("Invalid JSON response")))
                }
            } catch {
                self.logger.error("❌ Failed to parse generation response. template=\(template.name), message=\(error.localizedDescription)")
                completion(.failure(.apiError("Failed to parse generation response: \(error.localizedDescription)")))
            }
        }.resume()
    }
    
    private func prepareTrainingResource(
        with photos: [SelectedPhoto],
        progressHandler: FaceChainProgressHandler?,
        completion: @escaping (Result<String, FaceChainError>) -> Void
    ) {
        logger.info("🧱 Preparing training resource with \(photos.count) photos.")
        createTrainingArchive(from: photos) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let archiveURL):
                self.logger.debug("🗜️ Training archive created at \(archiveURL.lastPathComponent)")
                self.uploadTrainingArchive(archiveURL) { [weak self] uploadResult in
                    guard let self else { return }
                    
                    switch uploadResult {
                    case .success(let fileId):
                        self.logger.info("📤 Training archive uploaded. fileId=\(fileId)")
                        progressHandler?(.trainingArchiveUploaded)
                        self.createFinetuneJob(with: fileId) { [weak self] jobResult in
                            guard let self else { return }
                            
                            switch jobResult {
                            case .success(let jobId):
                                self.logger.info("🧪 Finetune job created. jobId=\(jobId)")
                                progressHandler?(.finetuneJobCreated)
                                self.pollFinetuneJob(jobId: jobId, attempts: 0, completion: completion)
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func createTrainingArchive(
        from photos: [SelectedPhoto],
        completion: @escaping (Result<URL, FaceChainError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let entries: [SimpleZipArchive.Entry] = try photos.enumerated().map { index, photo in
                    guard let data = photo.imageData else {
                        throw FaceChainError.invalidInput("Missing image data for photo at index \(index).")
                    }
                    return SimpleZipArchive.Entry(fileName: "photo_\(index).jpg", data: data)
                }
                
                let archiveData = try SimpleZipArchive.makeArchive(from: entries)
                let archiveURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("facechain-\(UUID().uuidString).zip")
                
                try archiveData.write(to: archiveURL, options: .atomic)
                completion(.success(archiveURL))
            } catch let error as FaceChainError {
                completion(.failure(error))
            } catch {
                completion(.failure(.fileIOError("Failed to create training archive: \(error.localizedDescription)")))
            }
        }
    }
    
    private func uploadTrainingArchive(
        _ archiveURL: URL,
        completion: @escaping (Result<String, FaceChainError>) -> Void
    ) {
        guard let url = URL(string: fileUploadEndpoint) else {
            completion(.failure(.invalidInput("File upload endpoint invalid")))
            return
        }
        
        guard let fileData = try? Data(contentsOf: archiveURL) else {
            completion(.failure(.fileIOError("Unable to read training archive data.")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(archiveURL.lastPathComponent)\"\r\n")
        body.append("Content-Type: application/zip\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            defer { try? FileManager.default.removeItem(at: archiveURL) }
            
            if let error = error {
                self.logger.error("❌ Training archive upload error: \(error.localizedDescription)")
                completion(.failure(.uploadError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.apiError("File upload response invalid")))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                self.logger.error("❌ Training archive upload failed. status=\(httpResponse.statusCode)")
                completion(.failure(.uploadError("File upload failed with status \(httpResponse.statusCode)")))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let uploadedFiles = dataDict["uploaded_files"] as? [[String: Any]],
                   let fileId = uploadedFiles.first?["file_id"] as? String {
                    self.logger.debug("📁 Training archive upload response parsed. fileId=\(fileId)")
                    completion(.success(fileId))
                } else {
                    completion(.failure(.uploadError("File upload response missing file_id")))
                }
            } catch {
                completion(.failure(.uploadError("Failed to parse upload response: \(error.localizedDescription)")))
            }
        }.resume()
    }
    
    private func createFinetuneJob(
        with fileId: String,
        completion: @escaping (Result<String, FaceChainError>) -> Void
    ) {
        guard let url = URL(string: finetuneEndpoint) else {
            completion(.failure(.invalidInput("Finetune endpoint invalid")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": "facechain-finetune",
            "training_file_ids": [fileId]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(.invalidInput("Failed to encode finetune payload")))
            return
        }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            
            if let error = error {
                self.logger.error("❌ Finetune job creation error: \(error.localizedDescription)")
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(.apiError("Finetune job creation failed")))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let output = json["output"] as? [String: Any],
                   let jobId = output["job_id"] as? String {
                    completion(.success(jobId))
                } else {
                    completion(.failure(.apiError("Finetune job response missing job_id")))
                }
            } catch {
                completion(.failure(.apiError("Failed to parse finetune job response: \(error.localizedDescription)")))
            }
        }.resume()
    }
    
    private func pollFinetuneJob(
        jobId: String,
        attempts: Int,
        completion: @escaping (Result<String, FaceChainError>) -> Void
    ) {
        guard attempts < self.maxTrainingPollingAttempts else {
            logger.error("⏱️ Finetune polling timeout. jobId=\(jobId), attempts=\(attempts), max=\(self.maxTrainingPollingAttempts)")
            completion(.failure(.apiError("Finetune job timeout after \(attempts) attempts (max: \(self.maxTrainingPollingAttempts))")))
            return
        }
        
        guard let url = URL(string: "\(finetuneEndpoint)/\(jobId)") else {
            completion(.failure(.invalidInput("Finetune status endpoint invalid")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            
            if let error = error {
                self.logger.error("❌ Finetune polling error. jobId=\(jobId), message=\(error.localizedDescription)")
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(.apiError("Failed to poll finetune job")))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let output = json["output"] as? [String: Any] {
                    
                    let status = (output["status"] as? String ??
                                  output["job_status"] as? String ?? "").uppercased()
                    
                    switch status {
                    case "SUCCEEDED":
                        if let resourceId = output["finetuned_output"] as? String ??
                            output["finetuned_resource_id"] as? String {
                            self.logger.info("🎉 Finetune job succeeded. jobId=\(jobId), resourceId=\(resourceId)")
                            completion(.success(resourceId))
                        } else {
                            completion(.failure(.apiError("Finetune job succeeded but no resource id returned")))
                        }
                        
                    case "FAILED":
                        let message = output["error_msg"] as? String ?? "Finetune job failed"
                        self.logger.error("❌ Finetune job failed. jobId=\(jobId), message=\(message)")
                        completion(.failure(.apiError(message)))
                        
                    default:
                        self.logger.debug("⏳ Finetune job pending. jobId=\(jobId), status=\(status), attempt=\(attempts)")
                        let interval = self.trainingPollingInterval
                        DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                            self.pollFinetuneJob(
                                jobId: jobId,
                                attempts: attempts + 1,
                                completion: completion
                            )
                        }
                    }
                } else {
                    completion(.failure(.apiError("Invalid finetune job response")))
                }
            } catch {
                completion(.failure(.apiError("Failed to parse finetune job response: \(error.localizedDescription)")))
            }
        }.resume()
    }
    
    private func extractImageURLs(from dictionary: [String: Any]) -> [String] {
        if let results = dictionary["results"] as? [[String: Any]] {
            let urls = results.compactMap { ($0["url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !urls.isEmpty {
                return urls
            }
        }
        
        if let imageUrl = (dictionary["image_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !imageUrl.isEmpty {
            return [imageUrl]
        }
        
        if let dataArray = dictionary["data"] as? [[String: Any]] {
            let urls = dataArray.compactMap { ($0["url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !urls.isEmpty {
                return urls
            }
        }
        
        return []
    }
    
    private func extractImageCount(from dictionary: [String: Any], fallback: Int) -> Int {
        if let usage = dictionary["usage"] as? [String: Any],
           let imageCount = usage["image_count"] as? Int {
            return imageCount
        }
        
        if let metrics = dictionary["task_metrics"] as? [String: Any],
           let total = metrics["TOTAL"] as? Int {
            return total
        }
        
        return fallback
    }
    
    private func pollGenerationResult(
        taskId: String,
        attempts: Int,
        completion: @escaping (Result<[String], FaceChainError>) -> Void
    ) {
        logger.debug("🔄 Polling task. taskId=\(taskId), attempt=\(attempts)")
        
        guard attempts < self.maxPollingAttempts else {
            logger.error("⏱️ Generation polling timeout. taskId=\(taskId), attempts=\(attempts), max=\(self.maxPollingAttempts)")
            completion(.failure(.apiError("Generation polling timeout after \(attempts) attempts")))
            return
        }
        
        guard let url = URL(string: "\(taskEndpoint)/\(taskId)") else {
            logger.error("❌ Task endpoint invalid. taskId=\(taskId)")
            completion(.failure(.invalidInput("Task endpoint invalid")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            
            if let error = error {
                self.logger.error("❌ Polling request error. taskId=\(taskId), message=\(error.localizedDescription)")
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(.apiError("Failed to poll generation task")))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let output = json["output"] as? [String: Any] {
                    
                    let statusValue = output["status"] as? String ?? output["task_status"] as? String ?? ""
                    let status = statusValue.uppercased()
                    
                    switch status {
                    case "SUCCEEDED":
                        let urls = self.extractImageURLs(from: output)
                        if !urls.isEmpty {
                            let reportedCount = self.extractImageCount(from: output, fallback: urls.count)
                            self.logger.info("✅ Generation task succeeded. taskId=\(taskId), images=\(urls.count), reported=\(reportedCount)")
                            completion(.success(urls))
                        } else if let imageUrl = output["image_url"] as? String {
                            self.logger.info("✅ Generation task succeeded with image_url. taskId=\(taskId)")
                            completion(.success([imageUrl]))
                        } else {
                            self.logger.error("❌ Task succeeded but no image URL. taskId=\(taskId)")
                            completion(.failure(.apiError("Task succeeded but no image URL returned")))
                        }
                        
                    case "FAILED":
                        let message = output["error_msg"] as? String ?? "Generation failed"
                        self.logger.error("❌ Generation task failed. taskId=\(taskId), message=\(message)")
                        completion(.failure(.apiError(message)))
                        
                    default:
                        self.logger.debug("⏳ Task still running. taskId=\(taskId), status=\(status)")
                        let interval = self.pollingInterval
                        DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                            self.pollGenerationResult(
                                taskId: taskId,
                                attempts: attempts + 1,
                                completion: completion
                            )
                        }
                    }
                } else {
                    self.logger.error("❌ Invalid task response. taskId=\(taskId)")
                    completion(.failure(.apiError("Invalid task response")))
                }
            } catch {
                self.logger.error("❌ Failed to parse task response. taskId=\(taskId), message=\(error.localizedDescription)")
                completion(.failure(.apiError("Failed to parse task response: \(error.localizedDescription)")))
            }
        }.resume()
    }
}

// MARK: - Error Types

enum FaceChainError: LocalizedError {
    case invalidInput(String)
    case networkError(String)
    case apiError(String)
    case uploadError(String)
    case downloadError(String)
    case fileIOError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .uploadError(let message):
            return "Upload error: \(message)"
        case .downloadError(let message):
            return "Download error: \(message)"
        case .fileIOError(let message):
            return "File I/O error: \(message)"
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
    
    mutating func appendUInt16(_ value: UInt16) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { buffer in
            append(contentsOf: buffer)
        }
    }
    
    mutating func appendUInt32(_ value: UInt32) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { buffer in
            append(contentsOf: buffer)
        }
    }
}

private struct SimpleZipArchive {
    struct Entry {
        let fileName: String
        let data: Data
    }
    
    static func makeArchive(from entries: [Entry]) throws -> Data {
        guard entries.count <= Int(UInt16.max) else {
            throw FaceChainError.fileIOError("Too many files to archive.")
        }
        
        var archiveData = Data()
        var centralDirectory = Data()
        var offset: UInt32 = 0
        
        for entry in entries {
            let nameData = Data(entry.fileName.utf8)
            guard nameData.count <= Int(UInt16.max) else {
                throw FaceChainError.fileIOError("File name too long: \(entry.fileName)")
            }
            guard entry.data.count <= Int(UInt32.max) else {
                throw FaceChainError.fileIOError("File data too large for ZIP format.")
            }
            
            let size = UInt32(entry.data.count)
            let crc = CRC32.checksum(for: entry.data)
            
            var localHeader = Data()
            localHeader.appendUInt32(0x04034B50)
            localHeader.appendUInt16(20) // version needed to extract
            localHeader.appendUInt16(0)  // general purpose bit flag
            localHeader.appendUInt16(0)  // compression method (store)
            localHeader.appendUInt16(0)  // last mod file time
            localHeader.appendUInt16(0)  // last mod file date
            localHeader.appendUInt32(crc)
            localHeader.appendUInt32(size) // compressed size
            localHeader.appendUInt32(size) // uncompressed size
            localHeader.appendUInt16(UInt16(nameData.count))
            localHeader.appendUInt16(0)    // extra field length
            localHeader.append(nameData)
            
            archiveData.append(localHeader)
            archiveData.append(entry.data)
            
            var centralEntry = Data()
            centralEntry.appendUInt32(0x02014B50)
            centralEntry.appendUInt16(20)  // version made by
            centralEntry.appendUInt16(20)  // version needed to extract
            centralEntry.appendUInt16(0)   // general purpose bit flag
            centralEntry.appendUInt16(0)   // compression method
            centralEntry.appendUInt16(0)   // last mod file time
            centralEntry.appendUInt16(0)   // last mod file date
            centralEntry.appendUInt32(crc)
            centralEntry.appendUInt32(size)
            centralEntry.appendUInt32(size)
            centralEntry.appendUInt16(UInt16(nameData.count))
            centralEntry.appendUInt16(0)   // extra field length
            centralEntry.appendUInt16(0)   // file comment length
            centralEntry.appendUInt16(0)   // disk number start
            centralEntry.appendUInt16(0)   // internal file attributes
            centralEntry.appendUInt32(0)   // external file attributes
            centralEntry.appendUInt32(offset)
            centralEntry.append(nameData)
            
            centralDirectory.append(centralEntry)
            
            offset = UInt32(archiveData.count)
        }
        
        let centralDirectoryOffset = UInt32(archiveData.count)
        archiveData.append(centralDirectory)
        
        var endRecord = Data()
        endRecord.appendUInt32(0x06054B50)
        endRecord.appendUInt16(0) // number of this disk
        endRecord.appendUInt16(0) // disk where central directory starts
        endRecord.appendUInt16(UInt16(entries.count))
        endRecord.appendUInt16(UInt16(entries.count))
        endRecord.appendUInt32(UInt32(centralDirectory.count))
        endRecord.appendUInt32(centralDirectoryOffset)
        endRecord.appendUInt16(0) // comment length
        
        archiveData.append(endRecord)
        return archiveData
    }
}

private struct CRC32 {
    private static let table: [UInt32] = {
        (0..<256).map { index -> UInt32 in
            var crc = UInt32(index)
            for _ in 0..<8 {
                if crc & 1 == 1 {
                    crc = 0xEDB88320 ^ (crc >> 1)
                } else {
                    crc >>= 1
                }
            }
            return crc
        }
    }()
    
    static func checksum(for data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[index]
        }
        return crc ^ 0xFFFF_FFFF
    }
}

