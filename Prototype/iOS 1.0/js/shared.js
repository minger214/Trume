/**
 * 共享工具函数库 - Trume iOS App原型
 */

// 全局对象挂载辅助函数
function mountToWindow(fnName, fn) {
    if (typeof window !== 'undefined') {
        window[fnName] = fn;
    }
}

// 按钮点击动画函数
function buttonClickAnimation(button, callback = null) {
    mountToWindow('buttonClickAnimation', buttonClickAnimation);
    button.classList.add('scale-95', 'opacity-70');
    setTimeout(() => {
        button.classList.remove('scale-95', 'opacity-70');
        if (callback && typeof callback === 'function') {
            callback();
        }
    }, 150);
}

// 显示toast消息
function showToast(message, type = 'info', duration = 3000) {
    mountToWindow('showToast', showToast);
    
    // 创建toast元素
    const toast = document.createElement('div');
    toast.className = 'fixed top-20 left-1/2 transform -translate-x-1/2 px-4 py-2 rounded-full text-white text-sm z-50 flex items-center shadow-lg opacity-0 transition-opacity duration-300';
    
    // 简化图标和背景色处理
    let iconClass = 'fa-info-circle';
    
    // 处理预定义类型
    if (type === 'success') {
        toast.classList.add('bg-success');
        iconClass = 'fa-check-circle';
    } else if (type === 'error') {
        toast.classList.add('bg-error');
        iconClass = 'fa-times-circle';
    } else {
        // 使用自定义图标或默认图标
        iconClass = type.startsWith('fa-') ? type : 'fa-info-circle';
        toast.classList.add('bg-darkSecondary');
    }
    
    toast.innerHTML = `<i class="fa ${iconClass} mr-2"></i>${message}`;
    
    // 添加toast到body
    document.body.appendChild(toast);
    
    // 显示toast
    setTimeout(() => {
        toast.classList.remove('opacity-0');
    }, 10);
    
    // 指定时间后隐藏toast
    setTimeout(() => {
        toast.classList.add('opacity-0');
        setTimeout(() => {
            if (document.body.contains(toast)) {
                document.body.removeChild(toast);
            }
        }, 300);
    }, duration);
}

// 本地存储辅助函数
function getStorageItem(key, defaultValue = null) {
    try {
        const item = localStorage.getItem(key);
        return item ? JSON.parse(item) : defaultValue;
    } catch (error) {
        console.error('Error parsing storage item:', error);
        return defaultValue;
    }
}

function setStorageItem(key, value) {
    try {
        localStorage.setItem(key, JSON.stringify(value));
        return true;
    } catch (error) {
        console.error('Error saving storage item:', error);
        return false;
    }
}

// 项目数据管理函数
function saveProjects(projects) {
    mountToWindow('saveProjects', saveProjects);
    return setStorageItem('projects', projects);
}

function getProjects() {
    mountToWindow('getProjects', getProjects);
    return getStorageItem('projects', []);
}

function getCurrentSessionProjects() {
    mountToWindow('getCurrentSessionProjects', getCurrentSessionProjects);
    return getStorageItem('currentSessionProjects', []);
}

function saveCurrentSessionProjects(projects) {
    mountToWindow('saveCurrentSessionProjects', saveCurrentSessionProjects);
    return setStorageItem('currentSessionProjects', projects);
}

// 用户数据管理函数
function saveUserData(userData) {
    mountToWindow('saveUserData', saveUserData);
    const result = setStorageItem('userData', userData);
    // 数据更新后刷新UI
    if (result) updateCreditsButton();
    return result;
}

function getUserData() {
    mountToWindow('getUserData', getUserData);
    return getStorageItem('userData', { isPremiumMember: false, credits: 0 });
}

// 更新积分按钮显示
function updateCreditsButton() {
    mountToWindow('updateCreditsButton', updateCreditsButton);
    // 缓存DOM引用以提高性能
    const creditsButton = document.getElementById('credits-button');
    if (creditsButton) {
        const userData = getUserData();
        const { isPremiumMember, credits } = userData;
        
        // 直接设置文本内容，避免不必要的DOM操作
        creditsButton.textContent = isPremiumMember ? `${credits}` : 'PRO';
    }
}

// 导航函数
function navigateTo(url, delay = 0) {
    mountToWindow('navigateTo', navigateTo);
    if (delay > 0) {
        setTimeout(() => {
            window.location.href = url;
        }, delay);
    } else {
        window.location.href = url;
    }
}

function goBack() {
    mountToWindow('goBack', goBack);
    window.history.back();
}

// 模态框管理类
class ModalManager {
    constructor(modalId) {
        this.modal = document.getElementById(modalId);
        if (!this.modal) return;
        
        this.modalContent = this.modal.querySelector('div');
        this.isOpen = false;
        this.setupSwipeGesture();
        this.setupClickOutside();
    }
    
    open() {
        if (!this.modal || this.isOpen) return;
        
        this.modal.classList.remove('hidden');
        this.isOpen = true;
        
        // 添加动画
        setTimeout(() => {
            if (this.modalContent) {
                this.modalContent.classList.add('transform', 'translate-y-0');
                this.modalContent.classList.remove('translate-y-full');
            }
        }, 10);
    }
    
    close() {
        if (!this.modal || !this.isOpen || !this.modalContent) return;
        
        this.modalContent.classList.add('translate-y-full');
        this.modalContent.classList.remove('translate-y-0');
        
        setTimeout(() => {
            this.modal.classList.add('hidden');
            this.isOpen = false;
        }, 300);
    }
    
    setupSwipeGesture() {
        if (!this.modalContent) return;
        
        let startY = 0;
        let currentY = 0;
        
        this.modalContent.addEventListener('touchstart', (e) => {
            startY = e.touches[0].clientY;
        });
        
        this.modalContent.addEventListener('touchmove', (e) => {
            if (!this.isOpen) return;
            
            currentY = e.touches[0].clientY;
            const diffY = currentY - startY;
            
            // 只允许向下滑动并限制移动距离
            if (diffY > 0) {
                const translateY = Math.min(diffY * 0.5, 100);
                this.modalContent.style.transform = `translateY(${translateY}px)`;
            }
        });
        
        this.modalContent.addEventListener('touchend', () => {
            if (!this.isOpen) return;
            
            const diffY = currentY - startY;
            
            // 如果滑动距离足够，关闭模态框
            if (diffY > 70) {
                this.close();
            } else {
                // 否则，重置位置
                this.modalContent.style.transform = 'translateY(0)';
            }
        });
    }
    
    setupClickOutside() {
        if (!this.modal) return;
        
        this.modal.addEventListener('click', (e) => {
            if (e.target === this.modal) {
                this.close();
            }
        });
    }
}

// 初始化共享功能
function initializeSharedFunctions() {
    mountToWindow('initializeSharedFunctions', initializeSharedFunctions);
    mountToWindow('ModalManager', ModalManager); // 挂载模态框管理类
    
    // 初始化积分按钮
    updateCreditsButton();
    
    // 为积分按钮添加点击事件（如果存在）
    const creditsButton = document.getElementById('credits-button');
    if (creditsButton) {
        creditsButton.addEventListener('click', function() {
            buttonClickAnimation(creditsButton, function() {
                const userData = getUserData();
                const { isPremiumMember, credits } = userData;
                
                showToast(isPremiumMember 
                    ? `You have ${credits} credits` 
                    : 'Get premium to earn credits'
                );
                
                navigateTo(isPremiumMember ? 'user-credits.html' : 'subscription.html', 500);
            });
        });
    }
}

// 页面加载完成后初始化共享功能
document.addEventListener('DOMContentLoaded', function() {
    initializeSharedFunctions();
});