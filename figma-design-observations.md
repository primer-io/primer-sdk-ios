# Figma Design Observations: Card Form Pattern

## Overall Container Structure

### Main Container (`pattern/card form`)
- **Layout**: Vertical stack (flex-col-reverse) with `gap-3` (12px spacing)
- **Dimensions**: Full width and height container
- **Children arranged from bottom to top** (reverse order):
  1. Card number input (order-5)
  2. Card network badges (order-4) 
  3. Expiry/CVV double input (order-3)
  4. Name input (order-2)

## Card Number Input Field

### Label
- **Text**: "Card number"
- **Font**: Inter Regular, 12px, line-height 16px
- **Color**: #212121 (dark gray)
- **Spacing**: 4px gap below label (gap-1)

### Input Container
- **Height**: 44px (h-11)
- **Background**: #FFFFFF (white)
- **Border**: 1px solid rgba(33,33,33,0.02) (very subtle border)
- **Border radius**: 4px (rounded)
- **Padding**: 12px all sides

### Input Content
- **Text**: "4111 2345 5432 6671"
- **Font**: Inter Regular, 16px, line-height 20px, letter-spacing -0.2px
- **Color**: #212121 (dark gray)
- **Layout**: Flexbox row with space-between alignment

### Trailing Icon (Visa Badge)
- **Position**: Right side of input
- **Size**: 28px width × 20px height (w-7 h-5)
- **Background**: #1434CB (Visa brand blue)
- **Border radius**: 2px (rounded-sm)
- **Content**: Visa logo in white

## Card Network Badges Row

### Container
- **Layout**: Horizontal flex wrap with `gap-1` (4px spacing)
- **Alignment**: Flex-start (left-aligned)
- **Flex behavior**: Wraps to new line if needed

### Individual Badge Specifications
Each card network badge has consistent sizing:
- **Dimensions**: 22.4px - 22.756px width × 16px height
- **Border radius**: 2px (rounded-sm)
- **Overflow**: Hidden (overflow-clip)

#### Specific Brand Colors:
- **Mastercard**: #FAFAFA (gray/50 background)
- **American Express**: #116DD0 (brand blue)
- **Visa**: #1434CB (brand blue)
- **Cartes Bancaires**: #FAFAFA (gray/50 background)
- **Discover**: #FAFAFA (gray/50 background)
- **Diners Club**: #254A9B (brand blue)
- **UnionPay**: #FAFAFA (gray/50 background)
- **Mir Pay**: #0F754E (brand green)
- **Maestro**: #FAFAFA (gray/50 background)
- **JCB**: #FAFAFA (gray/50 background)

## Double Input Row (Expiry/CVV)

### Container
- **Layout**: Horizontal flex row with `gap-3` (12px spacing)
- **Children**: Two equal-width inputs (basis-0, grow)

### Individual Input Structure
Each input in the double row follows the same pattern as the card number input:
- **Height**: 44px (h-11)
- **Background**: #FFFFFF (white)
- **Border**: 1px solid rgba(33,33,33,0.02)
- **Border radius**: 4px (rounded)
- **Padding**: 12px all sides

#### Left Input (Expiry)
- **Label**: "Expiry (MM/YY)"
- **Value**: "12/23"
- **Trailing icon**: Calendar icon (specific styling not detailed)

#### Right Input (CVV)
- **Label**: "CVV"
- **Value**: "123"
- **Trailing icon**: Security card icon (specific styling not detailed)

## Name Input Field

### Structure
Identical to card number input field:
- **Label**: "Name on card"
- **Value**: "Jonathan McFly"
- **Height**: 44px (h-11)
- **Background**: #FFFFFF (white)
- **Border**: 1px solid rgba(33,33,33,0.02)
- **Border radius**: 4px (rounded)
- **Padding**: 12px all sides

## Typography Scale

### Labels
- **Font**: Inter Regular
- **Size**: 12px
- **Line height**: 16px
- **Color**: #212121
- **Purpose**: Field labels

### Input Values
- **Font**: Inter Regular  
- **Size**: 16px
- **Line height**: 20px
- **Letter spacing**: -0.2px
- **Color**: #212121
- **Purpose**: Input field content

## Spacing System

### Vertical Spacing
- **Between main sections**: 12px (gap-3)
- **Between label and input**: 4px (gap-1)

### Horizontal Spacing
- **Between double inputs**: 12px (gap-3)
- **Between card network badges**: 4px (gap-1)
- **Input internal padding**: 12px all sides

### Input Dimensions
- **Standard input height**: 44px
- **Card network badge height**: 16px
- **Card network badge widths**: ~22.4-22.8px (varies by brand)

## Color Palette

### Backgrounds
- **Input backgrounds**: #FFFFFF (white)
- **Card badge backgrounds**: Various brand colors or #FAFAFA (gray/50)

### Text
- **All text**: #212121 (dark gray)

### Borders
- **Input borders**: rgba(33,33,33,0.02) (very subtle)

### Brand Colors
- **Visa**: #1434CB (blue)
- **American Express**: #116DD0 (blue)
- **Mir Pay**: #0F754E (green)
- **Diners Club**: #254A9B (blue)
- **Other brands**: #FAFAFA (neutral gray)

## Key Design Principles

1. **Consistent input height**: All inputs are 44px tall
2. **Unified spacing**: 12px between sections, 4px for tight spacing
3. **Subtle borders**: Very light rgba borders for clean appearance
4. **Brand-accurate colors**: Each card network uses official brand colors
5. **Flexible layout**: Card badges wrap, inputs grow to fill available space
6. **Clear hierarchy**: Labels are smaller (12px) than values (16px)
7. **Rounded corners**: Consistent 4px radius on inputs, 2px on badges

## Implementation Notes for iOS

- The reverse flex order may need special handling in iOS layout systems
- Card network badges need precise brand color matching
- Input field borders are very subtle and may need careful alpha values
- Typography requires Inter font family with specific weights and spacing
- The wrap behavior for card badges should adapt to available width
- Equal-width inputs in double row need proper constraint handling