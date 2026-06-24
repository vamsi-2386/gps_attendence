---
name: Obsidian Nexus
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#cbc3d7'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#958ea0'
  outline-variant: '#494454'
  surface-tint: '#d0bcff'
  primary: '#d0bcff'
  on-primary: '#3c0091'
  primary-container: '#a078ff'
  on-primary-container: '#340080'
  inverse-primary: '#6d3bd7'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#ffb869'
  on-tertiary: '#482900'
  tertiary-container: '#ca801e'
  on-tertiary-container: '#3f2300'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e9ddff'
  primary-fixed-dim: '#d0bcff'
  on-primary-fixed: '#23005c'
  on-primary-fixed-variant: '#5516be'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdcbb'
  tertiary-fixed-dim: '#ffb869'
  on-tertiary-fixed: '#2c1700'
  on-tertiary-fixed-variant: '#673d00'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-bold:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  mono-label:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.1em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  container-padding: 20px
  stack-gap: 12px
---

## Brand & Style

The design system is engineered for a high-performance enterprise environment, blending the precision of biometric technology with a sleek, futuristic aesthetic. It targets modern workforces who value efficiency and state-of-the-art security.

The visual style is **Futuristic Glassmorphism** set against an **Ultra-Minimalist Dark** backdrop. The interface should feel like a high-end command center—authoritative yet frictionless. It utilizes deep obsidian surfaces, vibrant purple accents that emit a digital "glow," and translucent layers to create a sense of depth and sophistication. Every interaction should feel intentional, rapid, and technologically advanced.

## Colors

The palette is built on a high-contrast dark foundation to minimize eye strain and emphasize primary action zones.

- **Primary Background:** #050505 (Obsidian). This absolute black provides the infinite canvas for depth.
- **Primary Accent:** #8b5cf6 (Vibrant Violet). Used for primary actions, active states, and biometric "scanning" light.
- **Success:** #10b981 (Electric Green). Reserved strictly for successful biometric matches and "In" status indicators.
- **Surface:** #121212 at 60% opacity with a backdrop blur. This creates the glassmorphic effect.
- **Borders:** Semi-transparent white (rgba(255, 255, 255, 0.08)) to define edges without adding visual weight.

## Typography

This design system utilizes a dual-font strategy. **Plus Jakarta Sans** is used for headings and display stats to provide a modern, friendly-yet-technical geometric feel. **Inter** is used for all body text and UI labels to ensure maximum legibility at small sizes, particularly for data-heavy payroll and calendar views.

- Use **display-lg** for time-stamps and primary status.
- Use **label-bold** for section headers and button text.
- Maintain tight letter spacing on headings to reinforce the "sleek" brand personality.

## Layout & Spacing

The layout follows a fluid-width mobile model with a fixed 20px horizontal margin. 

- **Grid:** Use an 8px base unit for all spacing.
- **Safe Areas:** Ensure a 44px top margin for status bars and 34px bottom margin for gesture indicators.
- **Scanning Interface:** The central scanning viewfinder should be centered both vertically and horizontally, occupying approximately 70% of the screen width.
- **Hierarchy:** Use larger vertical gaps (32px) to separate the biometric scanner from the action buttons to prevent accidental triggers.

## Elevation & Depth

Depth is conveyed through **Glassmorphism** and **Luminescent Glows** rather than traditional drop shadows.

- **Level 1 (Base):** #050505 background.
- **Level 2 (Cards):** Semi-transparent charcoal (#121212 at 70%) with a 20px backdrop-blur and a 1px solid border (rgba(255, 255, 255, 0.1)).
- **Level 3 (Interactive):** Elements like active buttons utilize a dual-glow: a soft 16px blur violet shadow (#8b5cf6 at 30%) and a sharp inner-glow to simulate a light-source from within the button.
- **Floating Nav:** The bottom navigation bar should use a 30px backdrop blur to allow content to scroll behind it while remaining legible.

## Shapes

The design system adopts a **Pill-Shaped (Level 3)** language to echo the organic nature of biometric data (fingerprints/faces) while maintaining a futuristic feel.

- **Buttons:** Fully rounded (pill) ends.
- **Cards:** 24px (rounded-lg) to 32px (rounded-xl) corner radius.
- **Input Fields:** 12px corner radius for a slightly more structured look compared to buttons.
- **Viewfinders:** Biometric scan zones use dashed circular paths or rounded squares with large corner radii.

## Components

### Buttons
Primary buttons are wide, pill-shaped, and filled with a #8b5cf6 gradient. They must feature a "Bloom" effect (a soft violet outer glow). Secondary buttons use a glassmorphic style with a subtle white border.

### Biometric Viewfinder
The scanning grid should be a 1px dashed line in vibrant violet. When a face/finger is detected, the lines should animate to Electric Green. Use a "Scanning Bar" that moves vertically across the viewfinder with a soft glow trailing it.

### Glassmorphic Cards
Used for Payroll and Leave summaries. Each card must have a 1px top-left highlight border (rgba(255, 255, 255, 0.15)) to simulate light hitting the edge of the glass.

### Bottom Navigation
A floating, translucent bar. Active states are indicated by a small violet dot beneath the icon and the icon itself transitioning to a filled violet state with a subtle glow.

### Status Chips
Small, pill-shaped indicators for "On Duty," "Late," or "Leave." These use low-opacity backgrounds (10%) of the status color with high-opacity text.

### Inputs
Search bars and text fields are recessed with a subtle inner shadow, creating a "carved" look into the obsidian background, surfaced with glassmorphism.