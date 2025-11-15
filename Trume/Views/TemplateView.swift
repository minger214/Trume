//
//  TemplateView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI
import PhotosUI
import UIKit

struct TemplateView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var activeCategory: TemplateCategory = .preset
    @State private var selectedTemplateID: String?
    @State private var isShowingEditor = false
    @State private var editorState = TemplateEditorState(category: .preset)
    @State private var showDeleteAlert = false
    @State private var templatePendingDeletion: TemplateItem?
    @Environment(\.presentationMode) var presentationMode
    
    private var currentTemplates: [TemplateItem] {
        viewModel.templates(for: activeCategory)
    }
    
    private var selectedTemplate: TemplateItem? {
        guard let id = selectedTemplateID else {
            return currentTemplates.first
        }
        return currentTemplates.first(where: { $0.id == id }) ?? currentTemplates.first
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.039, blue: 0.039)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                NavigationBar(
                    title: "Templates",
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        categorySelector
                        templatePreview
                        templateGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    addTemplateButton
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                        .background(
                            Color(red: 0.035, green: 0.039, blue: 0.039)
                                .ignoresSafeArea()
                        )
                }
            }
        }
        .onAppear { ensureSelection() }
        .onChange(of: activeCategory) { _ in
            ensureSelection()
        }
        .onChange(of: viewModel.presetTemplates) { _ in
            if activeCategory == .preset { ensureSelection() }
        }
        .onChange(of: viewModel.customTemplates) { _ in
            if activeCategory == .custom { ensureSelection() }
        }
        .sheet(isPresented: $isShowingEditor) {
            TemplateEditorSheet(
                state: $editorState,
                onDismiss: { isShowingEditor = false },
                onSave: handleEditorSave
            )
        }
        .alert("Delete Template?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let template = templatePendingDeletion {
                    viewModel.deleteTemplate(template)
                    viewModel.showToast(message: "Template deleted", type: .success)
                    templatePendingDeletion = nil
                    ensureSelection()
                }
            }
            Button("Cancel", role: .cancel) {
                templatePendingDeletion = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var categorySelector: some View {
        HStack(spacing: 12) {
            ForEach(TemplateCategory.allCases) { category in
                Button {
                    activeCategory = category
                    viewModel.showToast(message: "Switched to \(category.displayName)", type: .info)
                } label: {
                    Text(category.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(activeCategory == category ? .white : Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if activeCategory == category {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.51, green: 0.28, blue: 0.9),
                                            Color(red: 0.83, green: 0.2, blue: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color(red: 0.098, green: 0.098, blue: 0.098)
                                }
                            }
                        )
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var templatePreview: some View {
        Group {
            if let template = selectedTemplate {
                VStack(alignment: .leading, spacing: 12) {
                    TemplatePreviewCard(template: template)
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text(template.detail)
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.7))
                        
                        if template.category == .preset, template.isDefault {
                            Label("Default preset", systemImage: "star.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.56, green: 0.29, blue: 1.0))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            openEditor(for: template)
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                                .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                                .frame(height: 46)
                            .background(
                                LinearGradient(
                                        colors: [
                                            Color(red: 0.51, green: 0.28, blue: 0.9),
                                            Color(red: 0.83, green: 0.2, blue: 1.0)
                                        ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                                .cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            templatePendingDeletion = template
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.36))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                                .cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                VStack(alignment: .center, spacing: 16) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.098, green: 0.098, blue: 0.098))
                        .frame(height: 320)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.white.opacity(0.4))
                                Text("No templates yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.5))
                                Text("Tap “Add Template” to upload a new style image.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var templateGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(currentTemplates) { template in
                let canSetDefault = activeCategory == .preset
                TemplateCard(
                    template: template,
                    isSelected: template.id == selectedTemplate?.id,
                    canSetDefault: canSetDefault,
                    onSelect: {
                        selectedTemplateID = template.id
                    },
                    onEdit: {
                        openEditor(for: template)
                    },
                    onDelete: {
                        templatePendingDeletion = template
                        showDeleteAlert = true
                    },
                    onSetDefault: {
                        guard canSetDefault else { return }
                        viewModel.setDefaultPresetTemplate(id: template.id)
                        selectedTemplateID = template.id
                        viewModel.showToast(message: "\"\(template.name)\" set as default", type: .success)
                    }
                )
            }
        }
        .padding(.bottom, 60)
    }
    
    private var addTemplateButton: some View {
        Button {
            openEditor(for: nil)
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add Template")
                            .font(.system(size: 16, weight: .semibold))
            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
            .frame(height: 52)
                            .background(
                                LinearGradient(
                    colors: [
                        Color(red: 0.51, green: 0.28, blue: 0.9),
                        Color(red: 0.83, green: 0.2, blue: 1.0)
                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openEditor(for template: TemplateItem?) {
        if let template = template {
            editorState = TemplateEditorState(template: template)
        } else {
            editorState = TemplateEditorState(category: activeCategory)
        }
        isShowingEditor = true
    }
    
    private func handleEditorSave(_ state: TemplateEditorState) {
        let trimmedName = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            viewModel.showToast(message: "Please enter a template name", type: .error)
            return
        }
        
        let trimmedDetail = state.detail.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetCategory = state.original?.category ?? state.category
        
        if let original = state.original {
            var updated = original
            updated.name = trimmedName
            updated.detail = trimmedDetail.isEmpty ? original.detail : trimmedDetail
            
            if let imageData = state.imageData {
                let base64 = imageData.base64EncodedString()
                updated.imageSource = .base64(base64)
            }
            
            viewModel.updateTemplate(updated)
            selectedTemplateID = updated.id
            viewModel.showToast(message: "Template updated", type: .success)
        } else {
            guard let imageData = state.imageData else {
                viewModel.showToast(message: "Please select an image", type: .error)
                return
            }
            
            let base64 = imageData.base64EncodedString()
            let detail = trimmedDetail.isEmpty ? "Custom template" : trimmedDetail
            let styleCode = viewModel.styleCode(from: trimmedName)
            let newTemplate = TemplateItem(
                name: trimmedName,
                detail: detail,
                category: targetCategory,
                styleCode: styleCode,
                imageSource: .base64(base64),
                isSystemTemplate: false
            )
            
            viewModel.addTemplate(newTemplate)
            selectedTemplateID = newTemplate.id
            viewModel.showToast(message: "Template added", type: .success)
        }
        
        activeCategory = targetCategory
        ensureSelection()
        isShowingEditor = false
    }
    
    private func ensureSelection() {
        let templates = currentTemplates
        guard !templates.isEmpty else {
            selectedTemplateID = nil
            return
        }
        
        if let selectedTemplateID,
           templates.contains(where: { $0.id == selectedTemplateID }) {
            return
        }
        
        if activeCategory == .preset,
           let defaultTemplate = templates.first(where: { $0.isDefault }) {
            selectedTemplateID = defaultTemplate.id
        } else {
            selectedTemplateID = templates.first?.id
        }
    }
}

// MARK: - Template Preview Components

private struct TemplateCard: View {
    let template: TemplateItem
    let isSelected: Bool
    let canSetDefault: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            TemplatePreviewCard(template: template)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color(red: 0.56, green: 0.29, blue: 1.0) : Color.clear, lineWidth: 2)
                )
                .overlay(alignment: .topLeading) {
                    if template.isDefault && canSetDefault {
                        Label("Default", systemImage: "star.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.56, green: 0.29, blue: 1.0).opacity(0.9))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    Menu {
                        if canSetDefault {
                            Button {
                                onSetDefault()
                            } label: {
                                Label(template.isDefault ? "Default Template" : "Set as Default", systemImage: template.isDefault ? "star.circle.fill" : "star")
                            }
                            .disabled(template.isDefault)
                        }
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                    }
                }
            
            Text(template.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .padding(10)
        .background(Color(red: 0.098, green: 0.098, blue: 0.098))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 6)
        .onTapGesture(perform: onSelect)
        .contentShape(Rectangle())
    }
}

private struct TemplatePreviewCard: View {
    let template: TemplateItem
    
    var body: some View {
        Group {
            switch template.imageSource {
            case .remote(let url):
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ShimmerPlaceholder()
                }
            case .base64(let base64):
                if let data = Data(base64Encoded: base64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ShimmerPlaceholder()
                }
            }
        }
        .background(Color.black.opacity(0.3))
        .clipped()
    }
}

private struct ShimmerPlaceholder: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.08))
            .overlay(
                    LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.2), Color.white.opacity(0.05)]),
                        startPoint: .leading,
                        endPoint: .trailing
                )
                .offset(x: phase)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 320
                }
            }
    }
}

// MARK: - Template Editor

private struct TemplateEditorSheet: View {
    @Binding var state: TemplateEditorState
    let onDismiss: () -> Void
    let onSave: (TemplateEditorState) -> Void
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var isLoadingImage = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Template Info")) {
                    TextField("Template Name", text: $state.name)
                        .textInputAutocapitalization(.words)
                    TextField("Description", text: $state.detail, axis: .vertical)
                        .lineLimit(1...3)
                }
                
                Section(header: Text("Preview Image")) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(height: 220)
                        
                        if isLoadingImage {
                            ProgressView()
                        } else if let previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        } else if let source = state.existingImageSource {
                            TemplateImageDisplay(source: source)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("Select an image to use as the template reference.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .frame(height: 220)
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(state.isEditing ? "Replace Image" : "Choose Image", systemImage: "photo")
                    }
                }
            }
            .navigationTitle(state.isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(state)
                    }
                    .disabled(state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                loadImage(from: newItem)
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        isLoadingImage = true
        Task {
            defer { isLoadingImage = false }
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let jpegData = uiImage.jpegData(compressionQuality: 0.9) {
                await MainActor.run {
                    previewImage = uiImage
                    state.imageData = jpegData
                }
            }
        }
    }
}

private struct TemplateImageDisplay: View {
    let source: TemplateItem.ImageSource
    
    var body: some View {
        Group {
            switch source {
            case .remote(let url):
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            case .base64(let base64):
                if let data = Data(base64Encoded: base64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

// MARK: - Editor State

private struct TemplateEditorState {
    var original: TemplateItem?
    var category: TemplateCategory
    var name: String
    var detail: String
    var imageData: Data?
    var existingImageSource: TemplateItem.ImageSource?
    
    var isEditing: Bool {
        original != nil
    }
    
    init(category: TemplateCategory) {
        self.original = nil
        self.category = category
        self.name = ""
        self.detail = ""
        self.imageData = nil
        self.existingImageSource = nil
    }
    
    init(template: TemplateItem) {
        self.original = template
        self.category = template.category
        self.name = template.name
        self.detail = template.detail
        self.imageData = nil
        self.existingImageSource = template.imageSource
    }
}
