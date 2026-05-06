---@meta

---@alias RGBA {[1]: number, [2]: number, [3]: number, [4]: number}
---@alias OnClickCallback fun()
---@alias OnValueChanged fun(value: number)
---@alias OnColorChanged fun(r: number, g: number, b: number, a: number)
---@alias OnTextChanged fun(text: string)
---@alias OnCheckedChanged fun(checked: boolean)
---@alias OnKeySelected fun(key: string)

---@class NUISeparatorConfig
---@field useLabel? boolean Use separator with label
---@field height? number Custom height

---@class NUIButtonConfig
---@field tooltip? string Tooltip shown on hover
---@field callback? OnClickCallback Called on click
---@field image? string|number Icon texture path or FileDataID
---@field imageSize? number Icon size (default: 16)
---@field width? number Width in pixels (default: 120)
---@field height? number Height in pixels (default: 24)

---@class NUIDropdownConfig
---@field options table Key-value pairs or array of {key, text} tables
---@field value? any Initial selected key
---@field callback? OnKeySelected Called when selection changes
---@field searchable? boolean Enable search/filter input (default: false)
---@field isFontPreview? boolean Show font preview in dropdown items

---@class NUIEditBoxConfig
---@field value? string Initial text value
---@field callback? OnTextChanged Called when text changes

---@class NUIColorPickerConfig
---@field color? RGBA Initial RGBA color {r, g, b, a}
---@field callback? OnColorChanged Called when color changes

---@class NUICheckboxConfig
---@field value? boolean Initial checked state
---@field callback? OnCheckedChanged Called when value changes
---@field msgPopup? boolean Show popup message on toggle
---@field msgText? string Popup text prefix
---@field msgOn? string Text shown for "on" state
---@field msgOff? string Text shown for "off" state

---@class NUISliderConfig
---@field min number Minimum value
---@field max number Maximum value
---@field step number Step increment
---@field value? number Initial value (defaults to min)
---@field labelWidth? number Label width in pixels
---@field callback? OnValueChanged Called when value changes

---@class NUIPositionCardConfig
---@field title? string Card header title (default: "Position Settings")
---@field db table Database table to read/write values
---@field dbKeys? NUIPositionCardDbKeys Custom keys for db fields
---@field defaults? table Default values for position settings
---@field onChangeCallback? fun() Called when any value changes
---@field showAnchorFrameType? boolean Show anchor frame type dropdown (default: true)
---@field showStrata? boolean Show strata dropdown (default: false)
---@field sliderRange? number[] Min/max for X/Y sliders (default: {-1000, 1000})

---@class NUIPositionCardDbKeys
---@field anchorFrameType? string Key for anchor frame type (default: "anchorFrameType")
---@field anchorFrameFrame? string Key for anchor frame name (default: "anchorFrameFrame")
---@field selfPoint? string Key for self anchor point (default: "AnchorFrom")
---@field anchorPoint? string Key for target anchor point (default: "AnchorTo")
---@field xOffset? string Key for X offset (default: "XOffset")
---@field yOffset? string Key for Y offset (default: "YOffset")
---@field strata? string Key for frame strata (default: "Strata")

---@class NUIFontSettingsCardConfig
---@field title? string Card header title (default: "Font Settings")
---@field db table Database table to read/write values
---@field dbKeys? NUIFontSettingsCardDbKeys Custom keys for db fields
---@field onChangeCallback? fun() Called when any value changes
---@field fontSizeRange? number[] Min/max for font size slider (default: {8, 72})
---@field searchable? boolean Enable font search (default: true)
---@field includeSoftOutline? boolean Include SOFTOUTLINE option (default: false)
---@field shadowOffsetRange? number[] Min/max for shadow offset sliders (default: {-5, 5})

---@class NUIFontSettingsCardDbKeys
---@field fontFace? string Key for font face (default: "FontFace")
---@field fontSize? string Key for font size (default: "FontSize")
---@field fontOutline? string Key for font outline (default: "FontOutline")
---@field shadow? string Key for shadow settings table (default: "FontShadow")

---@class NUITextConfig
---@field text? string|table|function The label/body text content
---@field height? number Row height in pixels (default: 34)
---@field bgMode? "show"|"border"|"hide" Background display mode
---@field wrapOn? boolean Enable word wrap

---@class NUIMultiLineEditBoxConfig
---@field value? string Initial text value
---@field height? number Container height in pixels (default: 80)
---@field tooltip? string Tooltip text shown on hover
---@field syntaxHighlight? boolean Enable Lua syntax highlighting
---@field callback? OnTextChanged Called on focus lost with new text

-- Widgets using Mixin pattern (methods defined in implementation files)
---@class NUIButton: NUIButtonMixin
---@class NUICard: NUICardMixin
---@field positionWidgets? table
---@field fontWidgets? table
---@field shadowSubWidgets? table
---@field shadowEnableCheck? Frame

---@class NUIRow: NUIRowMixin
---@field label? FontString

---@class NUIColorSwatch: Button, BackdropTemplate
---@field r number
---@field g number
---@field b number
---@field a number

---@class NUIColorPicker: NUIColorPickerMixin
---@field label FontString

---@class NUIEditBox: NUIEditBoxMixin
---@field label FontString

---@class NUIWidgetStateManager: NUIWidgetStateManagerMixin

---@class NUIMultiLineEditBox: NUIMultiLineEditBoxMixin
---@field label FontString

---@class NUIScrollbar: NUIScrollbarMixin

-- Widgets with inline methods (kept as @field declarations)
---@class NUISlider: Frame
---@field slider Slider
---@field label FontString
---@field valueEdit EditBox
---@field leftStepper Button
---@field rightStepper Button
---@field SetValue fun(self: NUISlider, value: number)
---@field GetValue fun(self: NUISlider): number
---@field SetMinMaxValues fun(self: NUISlider, min: number, max: number)
---@field SetEnabled fun(self: NUISlider, enabled: boolean)

---@class NUIDropdown: Frame
---@field dropdown NUIDropdownButton
---@field label FontString
---@field SetValue fun(self: NUIDropdown, value: any, silent?: boolean)
---@field SetSelected fun(self: NUIDropdown, value: any, silent?: boolean)
---@field GetValue fun(self: NUIDropdown): any
---@field GetSelected fun(self: NUIDropdown): any
---@field SetEnabled fun(self: NUIDropdown, enabled: boolean)
---@field UpdateOptions fun(self: NUIDropdown, newOptions: table)
---@field SetOptions fun(self: NUIDropdown, newOptions: table)
---@field UpdateColors fun(self: NUIDropdown)

---@class NUICheckbox: Frame
---@field toggle Frame
---@field label FontString
---@field SetValue fun(self: NUICheckbox, value: boolean, instant?: boolean)
---@field GetValue fun(self: NUICheckbox): boolean
---@field SetEnabled fun(self: NUICheckbox, enabled: boolean)

---@class NUISeparator: Frame
---@field SetEnabled fun(self: NUISeparator, enabled: boolean)

---@class NUIText: Frame
---@field container Frame
---@field SetEnabled fun(self: NUIText, enabled: boolean)

---@class GUIFrame
---@field ContentBuilders table<string, function>
---@field PanelBuilders table<string, function>
---@field sidebarExpanded table<string, boolean>
---@field Show fun(self: GUIFrame)
---@field RefreshContent fun(self: GUIFrame)
---@field SelectSidebarItem fun(self: GUIFrame, itemId: string)

---@class NRSKNUI
---@field GUIFrame GUIFrame
---@field Theme table
---@field db table
---@field LSM table
---@field GUI table
---@field PATH string
---@field FONT string

