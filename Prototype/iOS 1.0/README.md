# Trume - AI Photo Generator Android Prototype

This repository contains high-fidelity HTML prototypes for the Trume AI Photo Generator Android application. The prototypes are designed to replicate the look and feel of the actual mobile application, providing a visual reference for development with interactive features and simulated data persistence.

## Project Structure

```
Prototype/
├── css/
│   └── shared.css          # Shared CSS styles
├── images/                 # Image assets for the prototype
│   ├── camera-interface.png
│   ├── home-credits.png
│   ├── home-illustration.png
│   ├── home-introduce.png
│   ├── home-selected.png
│   ├── logo.svg
│   ├── photo-grid.png
│   ├── portfolio-generating.png
│   ├── portfolio-thumbnail.png
│   ├── share-page.png
│   ├── splash-screen.png
│   ├── subscription-credits.png
│   ├── subscription.png
│   ├── template-bg.svg
│   └── template-page.png
├── js/
│   └── shared.js           # Shared JavaScript utilities and functions
├── camera.html             # Camera interface screen
├── credit-purchase.html    # Credit purchase screen
├── home.html               # Home screen - photo upload interface
├── index.html              # Main entry point
├── portfolio-generating.html # Portfolio generation in-progress screen
├── portfolio-selected.html # Selected portfolio item view
├── portfolio.html          # User portfolio screen
├── select-photo.html       # Photo selection gallery
├── splash.html             # Splash screen
├── subscription.html       # Subscription plan selection screen
├── template.html           # Template selection screen
├── test-toast.html         # Toast message testing page
├── user-credits.html       # User credits and transaction history screen
└── README.md               # This documentation file
```

## Overview

The prototype includes all main screens that represent the complete user flow of the Trume AI Photo Generator app, with enhanced interactive capabilities:

1. **Splash Screen (`splash.html`)**
   - Displays the app logo and name
   - Automatically transitions to the template selection screen
   - Features a dark theme with minimal design

2. **Home Screen (`home.html`)**
   - Main interface for photo uploads
   - Displays "Show us what you look like" prompt
   - Features "Upload 4 photos" button
   - Provides camera and photo library options
   - Shows photo comparison examples
   - Displays user credit balance with Toast notifications on interaction

3. **Photo Selection Screen (`select-photo.html`)**
   - Gallery view for selecting photos
   - Three-column grid layout for photo thumbnails
   - Photo selection indicator with checkmark
   - Navigation controls with dropdown option

4. **Camera Screen (`camera.html`)**
   - Camera interface with viewfinder
   - Shutter button for capturing photos
   - Flash toggle and camera switch controls
   - Gallery access button

5. **Template Selection Screen (`template.html`)**
   - Shows a preview of the generated image
   - Includes navigation controls (back button)
   - Provides action buttons for saving and sharing the image
   - Displays a progress indicator at the bottom

6. **Portfolio Screen (`portfolio.html`)**
   - Displays user's saved projects in a grid layout
   - Shows project thumbnails with dates
   - Includes project options button
   - Navigation controls with back button

7. **Portfolio Generating Screen (`portfolio-generating.html`)**
   - Shows in-progress project generation
   - Displays estimated completion time
   - Includes progress bar with percentage
   - Button animations and interactive elements
   - Option to save current session projects

8. **Subscription Screen (`subscription.html`)**
   - Subscription plan selection interface
   - Shows Basic and Premium plan options with pricing
   - Features free trial toggle
   - Includes privacy policy and terms of use links
   - Transaction history recording functionality
   - Toast notifications for confirmation messages

9. **Credit Purchase Screen (`credit-purchase.html`)**
   - Credit package selection interface
   - Shows various credit options with pricing
   - Features easy cancellation notice
   - Includes terms of use links
   - Interactive credit selection with Toast feedback
   - Transaction history management

10. **User Credits Screen (`user-credits.html`)**
    - Displays user's current credit balance
    - Shows detailed transaction history with timestamps
    - Credit package purchase functionality
    - Transaction filtering by type
    - Toast notifications for user actions

## Core Functionality

### Toast Message System

The prototype implements a unified Toast message system through `shared.js` that provides consistent user feedback across all screens:

- **Features**: 
  - Customizable duration (short/long)
  - Support for Font Awesome icons
  - Queue management for multiple messages
  - Consistent styling and animation

- **Usage**: All screens import and use the `showToast(message, icon, duration)` function to provide user feedback for various actions such as:
  - Credit selection confirmation
  - Successful purchases
  - Navigation feedback
  - Error notifications

### Data Persistence

The prototype uses localStorage to simulate data persistence:

- **User Data Management**:
  - Credit balance tracking
  - Subscription status
  - Transaction history recording
  - Project saves

- **Transaction History**:
  - Records all credit purchases and uses
  - Includes timestamps, transaction type, and credit changes
  - Displays in reverse chronological order
  - Implements defensive programming to prevent data access errors

## Technologies Used

- **HTML5** - For the structure of the web pages
- **Tailwind CSS** - For styling the UI components (via CDN)
- **Font Awesome** - For icons (via CDN)
- **JavaScript** - For interactions, navigation, and simulated data persistence
- **localStorage** - For client-side data storage

## How to Use

1. Ensure all HTML files and directories (`css/`, `images/`, `js/`) are kept together in the same folder structure.

2. Open `index.html` or `splash.html` in a web browser to start the prototype flow.
   - Alternatively, you can directly open any individual screen to view it.

3. Navigate between screens using the provided UI controls:
   - Back buttons to return to previous screens
   - Share, Save, and Purchase buttons for respective actions
   - Interactive elements provide visual feedback via Toast messages

4. Test the full user journey:
   - Upload photos → Generate portfolio → Manage subscriptions → Purchase credits
   - Track your transaction history in the User Credits screen
   - Observe how actions affect your credit balance

## Design Notes

- The prototype is designed with a dark theme aesthetic, consistent with the original Figma design
- All text is displayed in English as per requirements
- The layout is optimized for Android devices with dimensions of 390px × 844px
- Touch-friendly UI elements with appropriate sizing for mobile interaction
- Subtle animations and transitions enhance the user experience
- Toast notifications provide immediate feedback for user actions

## Development Notes

- The prototype uses Tailwind CSS for styling, with custom utility classes defined for Android-specific dimensions and effects
- Font Awesome icons are used throughout the interface for intuitive visual cues
- JavaScript is used extensively for interactive features and simulated backend functionality
- The prototype implements defensive programming principles to handle edge cases and prevent errors
- Shared functionality is centralized in `shared.js` for maintainability and consistency

## License

This prototype is intended for internal use only as a reference for the Trume AI Photo Generator Android application development.