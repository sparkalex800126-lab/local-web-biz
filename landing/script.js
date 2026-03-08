/**
 * 在地網站 Landing Page - JavaScript
 * Features:
 * - Sticky navbar with scroll effect
 * - Mobile menu toggle
 * - Smooth scroll navigation
 * - Scroll reveal animations (IntersectionObserver)
 * - Form submission handling
 */

(function() {
    'use strict';

    // ================================================
    // DOM Elements
    // ================================================
    const navbar = document.getElementById('navbar');
    const mobileMenuBtn = document.getElementById('mobile-menu-btn');
    const mobileMenu = document.getElementById('mobile-menu');
    const contactForm = document.getElementById('contact-form');
    const navLinks = document.querySelectorAll('a[href^="#"]');
    const revealElements = document.querySelectorAll('.reveal');

    // ================================================
    // Navbar Scroll Effect
    // ================================================
    function handleNavbarScroll() {
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    }

    window.addEventListener('scroll', handleNavbarScroll, { passive: true });
    handleNavbarScroll(); // Initial check

    // ================================================
    // Mobile Menu Toggle
    // ================================================
    function toggleMobileMenu() {
        mobileMenu.classList.toggle('active');
        mobileMenuBtn.classList.toggle('active');

        // Toggle aria-expanded
        const isExpanded = mobileMenu.classList.contains('active');
        mobileMenuBtn.setAttribute('aria-expanded', isExpanded);
    }

    mobileMenuBtn.addEventListener('click', toggleMobileMenu);

    // Close mobile menu when clicking on a link
    mobileMenu.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', () => {
            mobileMenu.classList.remove('active');
            mobileMenuBtn.classList.remove('active');
        });
    });

    // Close mobile menu when clicking outside
    document.addEventListener('click', (e) => {
        if (!mobileMenu.contains(e.target) &&
            !mobileMenuBtn.contains(e.target) &&
            mobileMenu.classList.contains('active')) {
            mobileMenu.classList.remove('active');
            mobileMenuBtn.classList.remove('active');
        }
    });

    // ================================================
    // Smooth Scroll Navigation
    // ================================================
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            const href = link.getAttribute('href');

            // Only handle internal anchor links
            if (href.startsWith('#') && href.length > 1) {
                e.preventDefault();
                const target = document.querySelector(href);

                if (target) {
                    const navbarHeight = navbar.offsetHeight;
                    const targetPosition = target.getBoundingClientRect().top + window.pageYOffset;
                    const offsetPosition = targetPosition - navbarHeight - 20;

                    window.scrollTo({
                        top: offsetPosition,
                        behavior: 'smooth'
                    });
                }
            }
        });
    });

    // ================================================
    // Scroll Reveal Animation (IntersectionObserver)
    // ================================================
    const revealObserverOptions = {
        root: null,
        rootMargin: '0px 0px -50px 0px',
        threshold: 0.1
    };

    const revealObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                // Add stagger delay based on element index within its parent
                const parent = entry.target.parentElement;
                const siblings = parent.querySelectorAll('.reveal');
                const index = Array.from(siblings).indexOf(entry.target);

                // Limit stagger delay
                const delay = Math.min(index * 100, 300);

                setTimeout(() => {
                    entry.target.classList.add('active');
                }, delay);

                // Stop observing once revealed
                observer.unobserve(entry.target);
            }
        });
    }, revealObserverOptions);

    // Observe all reveal elements
    revealElements.forEach(el => {
        revealObserver.observe(el);
    });

    // ================================================
    // Contact Form Handling
    // ================================================
    if (contactForm) {
        contactForm.addEventListener('submit', (e) => {
            e.preventDefault();

            // Collect form data
            const formData = new FormData(contactForm);
            const data = {
                name: formData.get('name'),
                phone: formData.get('phone'),
                store: formData.get('store'),
                message: formData.get('message')
            };

            // Basic validation
            if (!data.name || !data.phone || !data.store) {
                showFormMessage('請填寫所有必填欄位', 'error');
                return;
            }

            // Phone validation (Taiwan mobile format)
            const phoneRegex = /^09\d{2}-?\d{3}-?\d{3}$/;
            if (!phoneRegex.test(data.phone.replace(/-/g, ''))) {
                showFormMessage('請輸入有效的手機號碼', 'error');
                return;
            }

            // Simulate form submission
            const submitBtn = contactForm.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.textContent = '送出中...';
            submitBtn.disabled = true;

            // Simulate API call
            setTimeout(() => {
                showFormMessage('感謝您的詢問！我們會在 24 小時內與您聯繫。', 'success');
                contactForm.reset();
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
            }, 1000);
        });
    }

    function showFormMessage(message, type) {
        // Remove existing message
        const existingMessage = contactForm.querySelector('.form-message');
        if (existingMessage) {
            existingMessage.remove();
        }

        // Create message element
        const messageEl = document.createElement('div');
        messageEl.className = `form-message form-message-${type}`;
        messageEl.textContent = message;
        messageEl.style.cssText = `
            padding: 1rem;
            margin-bottom: 1rem;
            border-radius: 8px;
            font-weight: 500;
            ${type === 'success'
                ? 'background: #D1FAE5; color: #065F46; border: 1px solid #6EE7B7;'
                : 'background: #FEE2E2; color: #991B1B; border: 1px solid #FCA5A5;'
            }
        `;

        // Insert at top of form
        contactForm.insertBefore(messageEl, contactForm.firstChild);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            messageEl.remove();
        }, 5000);
    }

    // ================================================
    // Passive scroll listener for better performance
    // ================================================
    let ticking = false;

    function onScroll() {
        if (!ticking) {
            window.requestAnimationFrame(() => {
                handleNavbarScroll();
                ticking = false;
            });
            ticking = true;
        }
    }

    // Use passive listener for scroll
    window.addEventListener('scroll', onScroll, { passive: true });

    // ================================================
    // Preload critical resources
    // ================================================
    document.addEventListener('DOMContentLoaded', () => {
        // Mark page as loaded
        document.body.classList.add('loaded');

        // Trigger initial reveal for elements already in viewport
        revealElements.forEach(el => {
            const rect = el.getBoundingClientRect();
            if (rect.top < window.innerHeight && rect.bottom > 0) {
                el.classList.add('active');
            }
        });
    });

})();
