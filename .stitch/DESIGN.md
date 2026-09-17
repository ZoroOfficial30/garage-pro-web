# Design System: Garage Accounting Sunlight DS
**Project ID:** 10109041327133690116  
**Asset ID:** assets/10468624953666122558  
**Primary Currency:** OMR (ر.ع. Omani Rial, 3 decimal places)

---

## 1. Visual Theme & Ergonomics Philosophy

The **Garage Accounting Sunlight DS** is purpose-built for the rugged, high-tempo reality of automotive workshops and repair centers. Technicians and shop managers frequently use mobile devices with greasy, gloved hands, under intense direct sunlight, loud engine noise, and amidst fast-moving bay operations.

### Core Tenets:
1. **Uncompromising Sunlight Readability:** Built upon high-contrast light surfaces (`#FFFFFF` & `#F8FAFC`) framed by defined `#CBD5E1` borders and `#0F172A` deep slate text, eliminating screen washout in outdoor workbays.
2. **Grease-Resistant Tactile Targets:** All touch targets, buttons, and segmented pills maintain a minimum height of `54px – 64px`, with generous thumb-friendly margins to prevent mis-taps.
3. **Conversational & Voice-First Input:** Centered around a massive `72px` circular audio FAB for hands-free speech logging of transactions in multiple dialects.
4. **Action Safeguards (Undo Mechanism):** Every financial or inventory action triggers an inline, high-contrast confirmation banner with a prominent 5-second `UNDO` button.
5. **Primary Currency & Multi-Locale Native:** 
   * **Main Currency:** **OMR (Omani Rial / ر.ع.)** with standard 3-decimal precision (`OMR 8,450.000`).
   * **Secondary Support:** Multi-currency options (`$ USD`, `৳ BDT`, `₹ INR`, `د.إ AED`, `€ EUR`, `£ GBP`).
   * **Languages:** Full typographic support for English, Arabic (العربية), Bangla (বাংলা), and Hindi (हिन्दी).

---

## 2. Color Palette & Semantic Roles

| Token Name | Hex Code | Semantic Role |
| :--- | :--- | :--- |
| **Primary Accent** | `#0284C7` (Sky Blue) | Brand identity, primary buttons, active navigation, active tabs |
| **Success / Money In** | `#059669` (Emerald Green) | Cash collected, payments settled, in-stock status, profit indicators |
| **Danger / Due / Alert** | `#E11D48` (Rose Red) | Customer overdue balances, stockouts, delete/cancel actions |
| **Warning / Low Stock** | `#D97706` (Amber) | Low inventory threshold, pending invoices, waiting for parts |
| **Surface Base** | `#FFFFFF` | Primary card background, input fields, popovers |
| **Surface Secondary** | `#F8FAFC` | Page canvas background, secondary containers |
| **High-Contrast Border** | `#CBD5E1` | Tactile border stroke (1.5px - 2px) on cards, chips, and dividers |
| **Text Primary** | `#0F172A` (Slate 900) | Razor-sharp headlines, numerals, and ledger labels |
| **Text Secondary** | `#475569` (Slate 600) | Metadata, secondary vehicle information, timestamps |

---

## 3. Typography Hierarchy

* **Font Family:** `Plus Jakarta Sans` (Google Fonts)
* **Numeral Sizing:** Glanceable numbers scaled to `18px – 28px` for arm's length reading.

* **Display / Stat Figures:** 28px – 32px | Bold (700) | Letter-spacing: -0.02em
* **Headline (H1 / Screen Title):** 22px – 24px | Bold (700)
* **Section Headers (H2):** 18px – 20px | Semi-Bold (600)
* **Body / Card Title:** 16px | Medium (500) | Line-height: 1.5
* **Action / Button Labels:** 16px – 18px | Semi-Bold (600)
* **Micro-Data / Timestamp:** 13px – 14px | Medium (500)

---

## 4. Component Stylings & Dimensions

### Buttons & Touch Targets
* **Standard Primary Button:** Height `56px – 64px`, radius `12px`, padding `0 24px`, background `#0284C7`, text `#FFFFFF`, bold `16px`.
* **Voice Action FAB:** Circular `72px x 72px`, elevated with shadow `0 8px 24px rgba(2, 132, 199, 0.35)`, dual concentric ripple animations.
* **Inline Dispense / Add Stock:** Height `48px – 54px`, high tactile contrast with distinct `+` / `–` icons.

### Cards & Containers
* **Border Radius:** `12px` (`ROUND_TWELVE`).
* **Borders:** `1.5px solid #CBD5E1`.
* **Card Elevation:** Subtle diffuse shadow (`0 2px 8px rgba(15, 23, 42, 0.05)`) with high edge-contrast.

### Safety Confirmation & Undo Banner
* **Position:** Fixed above bottom navigation or inline above primary form actions.
* **Structure:** Background `#0F172A`, text `#FFFFFF`, with bright amber/sky `UNDO (5s)` button and radial countdown progress bar.

---

## 5. Responsive Multi-Device Adaptability

* **Mobile (< 768px):** Single-column stacked stream, sticky bottom voice dock, bottom navigation bar with 56px touch height.
* **Tablet (768px – 1024px):** Split dual-pane view (e.g., Customers directory on left, interactive detail ledger on right; or Dashboard KPI grid + Bay status side-by-side).
* **Desktop / Web (> 1024px):** Persistent left sidebar navigation, expansive multi-column inventory tables, real-time analytics graphs.
