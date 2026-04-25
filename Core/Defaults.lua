-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Default settings table
local Defaults = {
    global = {
        UseGlobalProfile = false,  -- Switch to global profile
        GlobalProfile = "Default", -- Name of global profile to use

        -- Theme settings
        -- Mode: "preset", "class", or "custom"
        -- All theme presets are defined in AddonTheme.lua
        Theme = {
            mode           = "preset", -- Theme mode: preset, class, or custom
            selectedPreset = "NUI v2", -- Selected preset theme name
            customColors   = {},       -- Custom color overrides (used in custom mode)

            -- Font settings (shared across all modes)
            fontFace       = "Fonts\\FRIZQT__.TTF",
            fontSizeNormal = 12,
            fontSizeSmall  = 12,
            fontSizeLarge  = 16,
            fontOutline    = "OUTLINE",
            fontShadow     = false,
        },

        -- GUI State (only frame position/size persists across logins)
        GUIState = {
            frame = {
                point = nil,         -- Anchor point
                relativePoint = nil, -- Relative anchor point
                xOffset = nil,       -- Frame X offset
                yOffset = nil,       -- Frame Y offset
                width = nil,         -- Frame width
                height = nil,        -- Frame height
            },
            selectedGroupId = nil,   -- Currently selected sidebar item
            selectedTab = nil,       -- Currently selected tab in content
            minimized = false,       -- Is frame minimized
        },
    },
    profile = {
        TimeSpiral = {
            Enabled = true,
            IconSize = 40,

            ShowText = true,
            TextLabel = "FREE",
            TextColor = { 0, 1, 0, 1 },
            FontFace = "Expressway",
            FontSize = 14,
            FontOutline = "SOFTOUTLINE",
            FontShadow = {
                Enabled = false,
                Color = { 0, 0, 0, 0 },
                OffsetX = 0,
                OffsetY = 0,
            },

            ShowTimer = true,
            TimerTextColor = { 1, 1, 1, 1 },
            TimerFontSize = 16,

            GlowEnabled = true,
            GlowType = "proc",
            GlowColor = { 0, 1, 0, 1 },
            GlowLines = 8,
            GlowFrequency = 0.25,
            GlowLength = 8,
            GlowThickness = 2,
            GlowBorder = false,
            GlowScale = 1,
            GlowStartAnim = false,
            GlowDuration = 1,

            Strata = "HIGH",
            anchorFrameType = "UIPARENT",
            ParentFrame = "UIParent",
            Position = {
                AnchorFrom = "CENTER",
                AnchorTo = "CENTER",
                XOffset = 100,
                YOffset = 0,
            },
        },

        RangeChecker = {
            Enabled = true,
            CombatOnly = false,
            UpdateThrottle = 0.1,
            MaxRange = 40,

            -- Colors
            ColorOne = { 1, 0, 0 },
            ColorTwo = { 1, 0.42, 0 },
            ColorThree = { 1, 0.82, 0 },
            ColorFour = { 0, 1, 0 },

            FontFace = "Expressway",
            FontSize = 24,
            FontOutline = "SOFTOUTLINE",
            FontShadow = {
                Enabled = false,
                Color = { 0, 0, 0, 1 },
                OffsetX = 1,
                OffsetY = -1,
            },

            Strata = "HIGH",
            anchorFrameType = "SELECTFRAME",
            ParentFrame = "UIParent",
            Position = {
                AnchorFrom = "CENTER",
                AnchorTo = "CENTER",
                XOffset = 0,
                YOffset = -290,
            },
        },

        BlizzardRM = {
            Enabled = true,
            -- Position Settings
            Position = {        -- Position settings
                YOffset = -650, -- Y offset
            },
            Strata = "HIGH",
            FadeOnMouseOut = true,
            FadeInDuration = 0.3,
            FadeOutDuration = 3,
            Alpha = 0,
        },

        -- ElvUI Integration
        UseElvUI = {
            Enabled = true, -- Master toggle for ElvUI integration (disables my skins when true to avoid conflicts)
        },
        -- Minimap Icon Settings
        Minimap = {
            hide = false,        -- Show/hide minimap icon
            LoginMessage = true, -- Show login chat message
        },
        -- Combat Timer Settings
        CombatTimer = {
            Enabled = true,                      -- Enable/disable combat timer
            CombatOnly = false,                  -- Only show timer during combat
            Format = "MM:SS",                    -- Time format
            FontSize = 28,                       -- Font size
            FontFace = "Expressway",             -- Font face
            FontOutline = "SOFTOUTLINE",         -- Font outline
            FontShadow = {                       -- Font shadow settings
                Enabled = false,                 -- Enable font shadow
                OffsetX = 0,                     -- X offset
                OffsetY = 0,                     -- Y offset
                Color = { 0, 0, 0, 0 },          -- Shadow color (alpha 1 when enabled)
            },
            ColorInCombat = { 1, 1, 1, 1 },      -- Color when in combat
            ColorOutOfCombat = { 1, 1, 1, 0.7 }, -- Color when out of combat
            anchorFrameType = "SELECTFRAME",     -- Anchor type: SCREEN, UIPARENT, SELECTFRAME
            ParentFrame = "UIParent",            -- Parent frame
            Strata = "HIGH",                     -- Frame strata
            Position = {                         -- Position settings
                AnchorFrom = "CENTER",           -- Anchor point from
                AnchorTo = "CENTER",             -- Anchor point to
                XOffset = 0,                     -- X offset
                YOffset = -100,                  -- Y offset
            },
            Backdrop = {                         -- Backdrop settings
                Enabled = false,                 -- Enable/disable backdrop
                Color = { 0, 0, 0, 0.6 },        -- Backdrop color
                BorderColor = { 0, 0, 0, 1 },    -- Border color
                BorderSize = 1,
                bgWidth = 5,
                bgHeight = 5,

            },
            PrintEnd = false,
        },

        -- Combat Message Settings
        CombatMessage = {
            Enabled = true,               -- Enable/disable combat messages
            Strata = "HIGH",              -- Frame strata
            anchorFrameType = "UIPARENT", -- Anchor frame type (SCREEN, UIPARENT, SELECTFRAME)
            ParentFrame = "UIParent",     -- Parent frame name (when SELECTFRAME)
            FontFace = "Expressway",      -- Font face
            FontSize = 16,                -- Font size
            FontOutline = "SOFTOUTLINE",  -- Font outline: NONE, OUTLINE, THICKOUTLINE, SOFTOUTLINE
            FontShadow = {                -- Font shadow settings (disabled when SOFTOUTLINE)
                Enabled = false,          -- Enable font shadow
                Color = { 0, 0, 0, 0 },   -- Shadow color
                OffsetX = 0,              -- Shadow X offset
                OffsetY = 0,              -- Shadow Y offset
            },
            Position = {                  -- Position settings
                AnchorFrom = "CENTER",    -- Anchor point from
                AnchorTo = "CENTER",      -- Anchor point to
                XOffset = 0,              -- X offset
                YOffset = 172,            -- Y offset
            },
            Spacing = 4,                  -- Vertical spacing between messages
            Grow = "DOWN",                -- Grow direction: DOWN or UP
            Duration = 2.5,               -- How long messages are shown (seconds)
            -- Enter Combat Message
            EnterCombat = {
                Enabled = true,
                Text = "+ COMBAT +",
                Color = { 0.929, 0.259, 0, 1 },
                FontSize = 16,
            },
            -- Exit Combat Message
            ExitCombat = {
                Enabled = true,
                Text = "- COMBAT -",
                Color = { 0.788, 1, 0.627, 1 },
                FontSize = 16,
            },
            -- No Target Warning (persistent while in combat with no target)
            NoTarget = {
                Enabled = true,
                Text = "NO TARGET",
                Color = { 1, 0.4, 0, 1 },
                FontSize = 16,
            },
            -- Focus Target Died
            FocusDeath = {
                Enabled = true,
                Text = "FOCUS DIED",
                Color = { 1, 0.3, 0.3, 1 },
                FontSize = 16,
            },
            -- Party/Raid Death Announcement
            PartyDeath = {
                Enabled = true,
                UseClassColor = true,
                TextFormat = "%name DIED",
                TextColor = { 1, 1, 1, 1 },
                CombatOnly = true,
                LoadCondition = "ANYGROUP",
                FontSize = 16,
            },
        },

        -- Combat Cross Settings
        CombatCross = {
            Enabled = true,                   -- Enable/disable combat cross
            Strata = "HIGH",                  -- Frame strata
            anchorFrameType = "UIPARENT",     -- Anchor frame type (SCREEN, UIPARENT, SELECTFRAME)
            ParentFrame = "UIParent",         -- Parent frame name (when SELECTFRAME)
            Position = {                      -- Position settings
                AnchorFrom = "CENTER",        -- Anchor point from
                AnchorTo = "CENTER",          -- Anchor point to
                XOffset = 0,                  -- X offset
                YOffset = -10,                -- Y offset
            },
            ColorMode = "custom",             -- Color mode: "class" | "custom" | "theme"
            Color = { 0, 1, 0.169, 1 },       -- Cross color (used when ColorMode = "custom")
            Thickness = 22,                   -- Cross thickness (font size)
            Outline = true,                   -- Outline enabled
            RangeColorMeleeEnabled = false,   -- Color cross when out of melee range
            RangeColorRangedEnabled = false,  -- Color cross when out of ranged casting range
            OutOfRangeColor = { 1, 0, 0, 1 }, -- Color used when out of range
        },

        -- Battle Res Tracker Settings
        BattleRes = {
            Enabled = true,
            Strata = "HIGH",
            anchorFrameType = "UIPARENT",
            ParentFrame = "UIParent",
            Position = {
                AnchorFrom = "CENTER",
                AnchorTo = "CENTER",
                XOffset = 0.1,
                YOffset = -430,
            },
            FontFace = "Expressway",
            FontSize = 18,
            FontOutline = "SOFTOUTLINE",
            FontShadow = {
                Enabled = false,
                Color = { 0, 0, 0, 1 },
                OffsetX = 1,
                OffsetY = -1,
            },
            TextSpacing = 4,
            GrowthDirection = "RIGHT",
            Separator = "|",
            SeparatorCharges = "CR:",
            SeparatorColor = { 1, 1, 1, 1 },
            TimerColor = { 1, 1, 1, 1 },
            ChargeAvailableColor = { 0.3, 1, 0.3, 1 },
            ChargeUnavailableColor = { 1, 0.3, 0.3, 1 },
            Backdrop = {
                Enabled = true,
                Color = { 0, 0, 0, 0.8 },
                BorderColor = { 0, 0, 0, 1 },
                FrameWidth = 112,
                FrameHeight = 26,
            },
        },

        -- Incarnation Stack Tracker
        IncarnStacks = {
            Enabled = false,
            IconSize = 40,

            -- Stack Text (shows stack count)
            ShowStacks = true,
            StackTextColor = { 1, 1, 1, 1 },
            StackFontFace = "Expressway",
            StackFontSize = 16,
            StackFontOutline = "OUTLINE",

            -- Timer Text (on icon)
            ShowTimer = true,
            TimerTextColor = { 1, 1, 1, 1 },
            TimerFontFace = "Expressway",
            TimerFontSize = 15,
            TimerFontOutline = "SOFTOUTLINE",

            -- Glow
            GlowEnabled = true,
            GlowType = "pixel",
            GlowColor = { 1, 0.678, 0, 1 },

            -- Glow Shared Settings
            GlowXOffset = 0,
            GlowYOffset = 0,

            -- Pixel Glow Specific
            GlowLines = 7,
            GlowFrequency = 0.25,
            GlowLength = 8,
            GlowThickness = 1,
            GlowBorder = true,

            -- AutoCast Specific
            GlowScale = 1,

            -- Proc Specific
            GlowDuration = 1,
            GlowStartAnim = false,

            -- Position
            Strata = "HIGH",
            anchorFrameType = "UIPARENT",
            ParentFrame = "UIParent",
            Position = {
                AnchorFrom = "CENTER",
                AnchorTo = "CENTER",
                XOffset = 0,
                YOffset = -50,
            },
        },

        PetTexts = {
            Enabled = true, -- Master toggle
            -- State texts
            PetMissing = "PET MISSING",
            PetPassive = "PET PASSIVE",
            PetDead = "PET DEAD",
            -- State colors (RGBA)
            MissingColor = { 1, 0.82, 0, 1 },  -- Gold/yellow for missing
            PassiveColor = { 0.3, 0.7, 1, 1 }, -- Light blue for passive
            DeadColor = { 1, 0.2, 0.2, 1 },    -- Red for dead
            -- Font settings
            FontFace = "Expressway",           -- Font face
            FontSize = 25,                     -- Font size
            FontOutline = "SOFTOUTLINE",       -- Font outline (NONE, OUTLINE, THICKOUTLINE, SOFTOUTLINE)
            -- Position settings
            Strata = "HIGH",                   -- Frame strata
            anchorFrameType = "UIPARENT",      -- Anchor frame type
            ParentFrame = "UIParent",          -- Parent frame name
            Position = {                       -- Position settings
                AnchorFrom = "CENTER",         -- Anchor point from
                AnchorTo = "CENTER",           -- Anchor point to
                XOffset = 0,                   -- X offset
                YOffset = 105,                 -- Y offset
            },
        },

        -- Healer Mana Tracker (Party only - shows 1 healer)
        HealerMana = {
            Enabled = true,
            -- Frame settings
            IconSize = 40,
            FrameWidth = 120,

            -- Name text settings
            NameFontSize = 18,
            NameXOffset = 4,
            NameYOffset = 10,

            -- Mana text settings
            ManaFontSize = 18,
            ManaXOffset = 4,
            ManaYOffset = -10,

            -- Font settings
            FontFace = "Expressway",
            FontOutline = "SOFTOUTLINE",
            HighManaColor = { 1, 1, 1, 1 },

            -- Position settings
            Strata = "HIGH",
            anchorFrameType = "UIPARENT",
            ParentFrame = "UIParent",
            Position = {
                AnchorFrom = "CENTER",
                AnchorTo = "CENTER",
                XOffset = -537,
                YOffset = -72,
            },
        },

        -- Miscellaneous Settings
        Miscellaneous = {
            Recuperate = {
                Enabled = true,
                LoadInRaid = true,
                LoadInParty = false,
                Size = 40,
                Strata = "HIGH",
                anchorFrameType = "UIPARENT",
                ParentFrame = "UIParent",
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 100,
                    YOffset = 0,
                },
            },

            AuctionHouseFilter = {
                Enabled = true,
                AuctionHouse = {
                    CurrentExpansion = true,
                    FocusSearchBar = true,
                },
                CraftOrders = {
                    CurrentExpansion = true,
                    FocusSearchBar = false,
                },
                Auctionator = {
                    CurrentExpansion = true,
                    FocusSearchBar = false,
                },
            },

            HuntersMark = {
                Enabled = true,
                Color = { 1, 0.290, 0.301, 1 },
                -- Font settings
                FontFace = "Expressway",      -- Font face
                FontSize = 22,                -- Font size
                FontOutline = "SOFTOUTLINE",  -- Font outline (NONE, OUTLINE, THICKOUTLINE)
                -- Position settings
                Strata = "HIGH",              -- Frame strata
                anchorFrameType = "UIPARENT", -- Anchor frame type
                ParentFrame = "UIParent",     -- Parent frame name
                Position = {                  -- Position settings
                    AnchorFrom = "CENTER",    -- Anchor point from
                    AnchorTo = "CENTER",      -- Anchor point to
                    XOffset = 0,              -- X offset
                    YOffset = 320,            -- Y offset
                },
            },

            MiscVars = {
                Enabled = true,

                -- Cvar list
                nameplateUseClassColorForFriendlyPlayerUnitNames = true,
                nameplateShowOnlyNameForFriendlyPlayerUnits = true,
            },

            Gateway = {
                Enabled = true,
                Color = { 0, 1, 0 },
                -- Font settings
                FontFace = "Expressway",      -- Font face
                FontSize = 36,                -- Font size
                FontOutline = "SOFTOUTLINE",  -- Font outline (NONE, OUTLINE, THICKOUTLINE)
                -- Position settings
                Strata = "HIGH",              -- Frame strata
                anchorFrameType = "UIPARENT", -- Anchor frame type
                ParentFrame = "UIParent",     -- Parent frame name
                Position = {                  -- Position settings
                    AnchorFrom = "CENTER",    -- Anchor point from
                    AnchorTo = "CENTER",      -- Anchor point to
                    XOffset = 0,              -- X offset
                    YOffset = -319,           -- Y offset
                },
            },

            Durability = {
                Enabled = true,
                FontFace = "Expressway",
                FontOutline = "SOFTOUTLINE",

                WarningText = {
                    Enabled = true,
                    ShowPercent = 30,
                    CombatShowPercent = 0,
                    WarningColor = { 1, 0.537, 0.2, 1 },
                    FontSize = 18,
                    WarningText = "REPAIR NOW",
                    -- Position settings
                    Strata = "HIGH",              -- Frame strata
                    anchorFrameType = "UIPARENT", -- Anchor frame type
                    ParentFrame = "UIParent",     -- Parent frame name
                    Position = {                  -- Position settings
                        AnchorFrom = "CENTER",    -- Anchor point from
                        AnchorTo = "CENTER",      -- Anchor point to
                        XOffset = 0,              -- X offset
                        YOffset = 132,            -- Y offset
                    },
                },

                Text = {
                    Enabled = true,
                    UseStatusColor = true,
                    Color = { 1, 1, 1, 1 },
                    FontSize = 12,
                    DurColor = { 1, 1, 1, 1 },
                    DurText = "Dur: ",
                    -- Position settings
                    Strata = "HIGH",                 -- Frame strata
                    anchorFrameType = "SELECTFRAME", -- Anchor frame type
                    ParentFrame = "Minimap",         -- Parent frame name
                    Position = {                     -- Position settings
                        AnchorFrom = "BOTTOMLEFT",   -- Anchor point from
                        AnchorTo = "BOTTOMLEFT",     -- Anchor point to
                        XOffset = 1,                 -- X offset
                        YOffset = 18,                -- Y offset
                    },
                },
            },

            XPBar = {
                Enabled = true,
                HideBlizzardBar = true,
                hideWhenMax = true,
                width = 400,
                height = 24,
                FontFace = "Expressway", -- Font face
                FontOutline = "OUTLINE", -- Font outline
                FontSize = 14,
                Strata = "HIGH",
                anchorFrameType = "UIPARENT", -- Anchor frame type
                ParentFrame = "UIParent",     -- Parent frame name
                Position = {                  -- Position settings
                    AnchorFrom = "CENTER",    -- Anchor point from
                    AnchorTo = "CENTER",      -- Anchor point to
                    XOffset = 0,              -- X offset
                    YOffset = 500,
                },
                -- Statusbar coloring
                ColorMode = "theme",
                StatusColor = { 1, 1, 1, 1 },
                StatusBarTexture = "NorskenUI", -- LSM statusbar texture name

                -- Rested Coloring
                RestedColor = { 0.7803, 0.0000, 0.0000, 0.25 },

                -- Backdrop
                BackdropColor = { 0, 0, 0, 0.8 },
                BackdropBorderColor = { 0, 0, 0, 1 },

                -- Text Coloring
                TextColor = { 1, 1, 1, 1 },
            },

            CopyAnything = {
                Enabled = true, -- Master toggle
                key = "C",      -- Copy keybind
                mod = "ctrl",   -- ctrl, shift, alt
            },

            WhisperSounds = {
                Enabled = true,                                  -- Enable whisper sounds
                WhisperSound = "|cffe51039NorskenWhisper|r",     -- Sound for regular whispers
                BNetWhisperSound = "|cffe51039NorskenWhisper|r", -- Sound for Battle.net whispers
            },
            CursorCircle = {
                Enabled = true,            -- Enable cursor circle
                Size = 40,                 -- Circle size
                Texture = "Circle 3",      -- Selected texture
                Color = { 1, 1, 1, 1 },    -- Circle color (RGBA) - used when ColorMode = "custom"
                ColorMode = "theme",       -- Color mode: "class" | "custom" | "theme"
                VisibilityMode = "always", -- Visibility mode: "always" | "mouseDown"
                UseUpdateInterval = false, -- Use throttled updates (saves CPU but less smooth)
                UpdateInterval = 0.016,    -- Update interval in seconds (0.016 = ~60 FPS, lower = smoother but higher CPU)
                GCD = {
                    Mode = "integrated",
                    Size = 25,
                    Texture = "Circle 5",
                    SwipeColorMode = "custom",
                    SwipeColor = { 1, 1, 1, 1 },
                    Reverse = true,
                    HideOutOfCombat = false,
                    RingColorMode = "theme",
                    RingColor = { 1, 1, 1, 1 },
                },
            },
            Automation = {
                Enabled = true,         -- Master toggle
                SkipCinematics = true,  -- Skip in-game cinematics and movies
                HideTalkingHead = true, -- Hide talking head popup frame
                AutoSellJunk = true,    -- Auto sell grey items at merchants
                AutoRepair = true,      -- Auto repair gear at merchants
                UseGuildFunds = true,   -- Use guild bank for repairs when available
                AutoRoleCheck = true,   -- Auto accept role checks and LFG signups
                AutoFillDelete = true,  -- Auto fill DELETE text when deleting items
                AutoLoot = true,        -- Enable auto loot by default
            },
            DragonRiding = {
                Enabled = true,
                Width = 252,               -- Total width of the UI
                BarHeight = 6,             -- Height of each row
                Spacing = 3,               -- Spacing between rows
                FontFace = "Expressway",
                SpeedFontSize = 14,        -- Speed text font size
                Position = {               -- Position settings
                    AnchorFrom = "CENTER", -- Anchor point from
                    AnchorTo = "CENTER",   -- Anchor point to
                    XOffset = 0,           -- X offset
                    YOffset = 280,         -- Y offset
                },
                Colors = {
                    Vigor = { 0.898, 0.063, 0.224, 1 },       -- Normal vigor color
                    VigorThrill = { 0, 1, 0.137, 1 },         -- Thrill of the Skies active
                    WhirlingSurge = { 0.411, 0.8, 0.941, 1 }, -- Whirling Surge
                    SecondWind = { 0.917, 0.168, 0.901, 1 },  -- Second Wind
                },
            },
            CooldownStrings = {
                Enabled = true,
                Profiles = {}, -- { [name] = { String = "", Created = timestamp, SpecID = number } }
            },
            FocusCastbar = {
                Enabled = true,

                TargetMarker = {
                    Enabled = true,
                    Size = 30,
                    XOffset = -30,
                    YOffset = 0,
                    Anchor = "LEFT",
                },

                Width = 300,
                Height = 29,

                FontFace = "Expressway",
                FontSize = 14,
                FontOutline = "SOFTOUTLINE",
                FontShadow = {
                    Enabled = false,
                    Color = { 0, 0, 0, 1 },
                    OffsetX = 1,
                    OffsetY = -1,
                },

                Strata = "HIGH",
                anchorFrameType = "UIPARENT",
                ParentFrame = "UIParent",
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0,
                    YOffset = 220,
                },

                -- Colors
                CastColor = { 0.623, 0.749, 1, 1 },
                NotInterruptibleColor = { 0.780, 0.250, 0.250, 1 },
                HideNotInterruptible = false,
                TextColor = { 1, 1, 1, 1 },

                -- Backdrop
                BackdropColor = { 0, 0, 0, 0.8 },
                BorderColor = { 0, 0, 0, 1 },

                -- Statusbar
                StatusBarTexture = "NorskenUI",

                -- Hold Timer
                HoldTimer = {
                    Enabled = true,
                    Duration = 0.5,
                    InterruptedColor = { 0.1, 0.8, 0.1, 1 },
                    SuccessColor = { 0.780, 0.250, 0.250, 1 },
                },
                timeToHold = 0.5,

                -- Kick Indicator
                KickIndicator = {
                    Enabled = true,
                    NotReadyColor = { 0.5, 0.5, 0.5, 1 },
                    TickColor = { 0.1, 0.8, 0.1, 1 },
                },

                -- Target Names
                TargetNames = {
                    Anchor = "RIGHT",
                    XOffset = 0,
                    YOffset = -24,
                    FontSize = 14,
                },
            },
        },
        -- Skinning Settings (CDM, Buffs, Action Bars, etc.)
        Skinning = {
            BlizzardRM = {
                Enabled = true,
                -- Position Settings
                Position = {        -- Position settings
                    YOffset = -650, -- Y offset
                },
                Strata = "HIGH",
                FadeOnMouseOut = true,
                FadeInDuration = 0.3,
                FadeOutDuration = 3,
                Alpha = 0,
            },

            Battlenet = {
                Enabled = true,
                -- Position Settings
                anchorFrameType = "UIPARENT",  -- Anchor frame type
                ParentFrame = "UIParent",      -- Parent frame name
                Position = {                   -- Position settings
                    AnchorFrom = "BOTTOMLEFT", -- Anchor point from
                    AnchorTo = "BOTTOMLEFT",   -- Anchor point to
                    XOffset = 1,               -- X offset
                    YOffset = 247,             -- Y offset
                },
            },

            UICleanup = {
                Enabled = true,
            },

            Chat = {
                Enabled = true,
                Width = 448,
                Height = 245,
                FontFace = "Expressway", -- Module font face
                FontOutline = "OUTLINE", -- Module font outline
                EditBoxFontSize = 14,    -- EditBox Font size
                ChatFontSize = 12,       -- Chat Font size
                TabFontSize = 12,        -- Chat Tab Font size
                TabSpacing = 20,
                -- Tab Color Settings
                TabColors = {
                    AlertColor = { 1, 0, 0, 1 },                -- Red for new messages/alerts
                    ActiveColor = { 1, 1, 1, 1 },               -- White for selected/active tab
                    WhisperColor = { 1, 0.5, 0.8, 1 },          -- Pink for whisper tabs
                    InactiveColorMode = "custom",               -- "theme", "class", or "custom"
                    InactiveColor = { 0.898, 0.063, 0.224, 1 }, -- Custom color for inactive tabs
                },
                -- EditBox Backdrop Settings
                EditBox = {
                    BackdropColor = { 0, 0, 0, 0.8 }, -- EditBox background color
                    BorderColor = { 0, 0, 0, 1 },     -- EditBox border color
                },
                -- Backdrop Settings
                Backdrop = {                      -- Backdrop settings (text mode mainly)
                    Enabled = true,               -- Enable backdrop, if not enable, set alpha 0 on backdrop and borders
                    Color = { 0, 0, 0, 0.8 },     -- Background color
                    BorderColor = { 0, 0, 0, 1 }, -- Border color
                },
                -- Position Settings
                anchorFrameType = "UIPARENT",  -- Anchor frame type
                ParentFrame = "UIParent",      -- Parent frame name
                Position = {                   -- Position settings
                    AnchorFrom = "BOTTOMLEFT", -- Anchor point from
                    AnchorTo = "BOTTOMLEFT",   -- Anchor point to
                    XOffset = 1,               -- X offset
                    YOffset = 1,               -- Y offset
                },
            },

            -- Actionbars
            ActionBars = {
                Enabled = true,            -- Master toggle for action bar skinning
                HideProfTexture = true,    -- Hide profession quality textures
                HideMacroText = false,     -- Hide macro name text
                MouseoverOverride = false, -- Mouseover override when dragonriding for example
                Mouseover = {              -- Global mouseover settings (used when bar's globalOverride is true)
                    Enabled = false,
                    FadeInDuration = 0.3,
                    FadeOutDuration = 1,
                    Alpha = 0,
                },
                FontFace = "Expressway",
                FontOutline = "OUTLINE",

                -- Global Font Sizes (used when bar's FontSizes.GlobalOverride is true)
                FontSizes = {
                    KeybindSize = 12,
                    CooldownSize = 14,
                    ChargeSize = 12,
                    MacroSize = 10,
                },

                -- Text Anchor Settings
                KeybindAnchor = "TOPRIGHT",
                KeybindXOffset = -2,
                KeybindYOffset = -2,

                ChargeAnchor = "BOTTOMRIGHT",
                ChargeXOffset = -2,
                ChargeYOffset = 2,

                MacroAnchor = "BOTTOM",
                MacroXOffset = 0,
                MacroYOffset = 2,

                CooldownAnchor = "CENTER",
                CooldownXOffset = 0,
                CooldownYOffset = 0,
                -- Per-bar settings (all bars use same structure)
                Bars = {
                    Bar1 = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 40,
                        TotalButtons = 12,
                        Layout = "HORIZONTAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 12,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "BOTTOM",
                            AnchorTo = "BOTTOM",
                            XOffset = 0.1,
                            YOffset = 1.1,
                        },
                        Mouseover = {
                            GlobalOverride = true,
                            Enabled = true,
                            Alpha = 0,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 12,
                            CooldownSize = 14,
                            ChargeSize = 12,
                            MacroSize = 10,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    Bar2 = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 40,
                        TotalButtons = 12,
                        Layout = "HORIZONTAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 6,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "BOTTOM",
                            AnchorTo = "BOTTOM",
                            XOffset = 369.1,
                            YOffset = 1.1,
                        },
                        Mouseover = {
                            GlobalOverride = true,
                            Enabled = true,
                            Alpha = 0,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 12,
                            CooldownSize = 14,
                            ChargeSize = 12,
                            MacroSize = 10,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    Bar3 = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 40,
                        TotalButtons = 12,
                        Layout = "HORIZONTAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 12,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "BOTTOM",
                            AnchorTo = "BOTTOM",
                            XOffset = 0.1,
                            YOffset = 42.1,
                        },
                        Mouseover = {
                            GlobalOverride = true,
                            Enabled = true,
                            Alpha = 0,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 12,
                            CooldownSize = 14,
                            ChargeSize = 12,
                            MacroSize = 10,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    Bar4 = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 40,
                        TotalButtons = 12,
                        Layout = "VERTICAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 6,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "BOTTOMLEFT",
                            AnchorTo = "BOTTOMLEFT",
                            XOffset = 450.1,
                            YOffset = 1.1,
                        },
                        Mouseover = {
                            GlobalOverride = true,
                            Enabled = true,
                            Alpha = 0,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 12,
                            CooldownSize = 14,
                            ChargeSize = 12,
                            MacroSize = 10,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    Bar5 = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 40,
                        TotalButtons = 12,
                        Layout = "HORIZONTAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 6,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "BOTTOM",
                            AnchorTo = "BOTTOM",
                            XOffset = -368.1,
                            YOffset = 1.1,
                        },
                        Mouseover = {
                            GlobalOverride = true,
                            Enabled = true,
                            Alpha = 0,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 12,
                            CooldownSize = 14,
                            ChargeSize = 12,
                            MacroSize = 10,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    Bar6 = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 40,
                        TotalButtons = 12,
                        Layout = "VERTICAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 6,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "BOTTOMLEFT",
                            AnchorTo = "BOTTOMLEFT",
                            XOffset = 532.1,
                            YOffset = 1.1,
                        },
                        Mouseover = {
                            GlobalOverride = true,
                            Enabled = true,
                            Alpha = 0,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 12,
                            CooldownSize = 14,
                            ChargeSize = 12,
                            MacroSize = 10,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    Bar7 = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 40,
                        TotalButtons = 12,
                        Layout = "VERTICAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 12,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "LEFT",
                            AnchorTo = "LEFT",
                            XOffset = 1.1,
                            YOffset = 0.1,
                        },
                        Mouseover = {
                            GlobalOverride = true,
                            Enabled = false,
                            Alpha = 1,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 12,
                            CooldownSize = 14,
                            ChargeSize = 12,
                            MacroSize = 10,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    Bar8 = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 40,
                        TotalButtons = 12,
                        Layout = "VERTICAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 12,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "LEFT",
                            AnchorTo = "LEFT",
                            XOffset = 42.1,
                            YOffset = 0.1,
                        },
                        Mouseover = {
                            GlobalOverride = true,
                            Enabled = false,
                            Alpha = 1,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 12,
                            CooldownSize = 14,
                            ChargeSize = 12,
                            MacroSize = 10,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    PetBar = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 32,
                        TotalButtons = 10,
                        Layout = "HORIZONTAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 10,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = false,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "BOTTOM",
                            AnchorTo = "BOTTOM",
                            XOffset = 0.1,
                            YOffset = 83.1,
                        },
                        Mouseover = {
                            GlobalOverride = false,
                            Enabled = false,
                            Alpha = 0,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 10,
                            CooldownSize = 12,
                            ChargeSize = 10,
                            MacroSize = 8,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                    StanceBar = {
                        Enabled = true,
                        Spacing = 1,
                        ButtonSize = 32,
                        TotalButtons = 10,
                        Layout = "HORIZONTAL",
                        GrowthDirection = "RIGHT",
                        ButtonsPerLine = 10,
                        ParentFrame = "UIParent",
                        HideEmptyBackdrops = true,
                        BackdropColor = { 0, 0, 0, 0.8 },
                        BorderColor = { 0, 0, 0, 1 },
                        Position = {
                            AnchorFrom = "BOTTOM",
                            AnchorTo = "BOTTOM",
                            XOffset = 0.1,
                            YOffset = 117.1,
                        },
                        Mouseover = {
                            GlobalOverride = false,
                            Enabled = false,
                            Alpha = 0,
                        },
                        FontSizes = {
                            GlobalOverride = true,
                            KeybindSize = 10,
                            CooldownSize = 12,
                            ChargeSize = 10,
                            MacroSize = 8,
                        },
                        TextPositions = {
                            GlobalOverride = true,
                            KeybindAnchor = "TOPRIGHT",
                            KeybindXOffset = -2,
                            KeybindYOffset = -2,
                            ChargeAnchor = "BOTTOMRIGHT",
                            ChargeXOffset = -2,
                            ChargeYOffset = 2,
                            MacroAnchor = "BOTTOM",
                            MacroXOffset = 0,
                            MacroYOffset = -2,
                        },
                    },
                },
            },

            -- Minimap Skinning
            Minimap = {
                Enabled = true,              -- Master toggle for minimap skinning
                HideAddOnComp = true,        -- Hide the addon compartment button
                Size = 232,                  -- Minimap size (square)
                Position = {                 -- Position
                    AnchorFrom = "TOPRIGHT", -- Anchor point
                    AnchorTo = "TOPRIGHT",
                    X = -1,                  -- X offset from anchor
                    Y = -1,                  -- Y offset from anchor
                },
                Border = {                   -- Border settings
                    Thickness = 1,           -- Border thickness
                    Color = { 0, 0, 0, 1 },  -- Border color
                },

                -- MiniMap Elements
                Mail = {                   -- Mail icon
                    Scale = 1.0,           -- Scale of mail icon
                    Anchor = "TOPRIGHT",   -- Anchor point
                    X = -7,                -- X offset
                    Y = -39,               -- Y offset
                },
                InstanceDifficulty = {     -- Instance difficulty
                    Scale = 0.8,           -- Scale of difficulty icon
                    Anchor = "TOPLEFT",    -- Anchor point
                    X = 2,                 -- X offset
                    Y = -2,                -- Y offset
                },
                QueueStatus = {            -- Queue status button
                    Scale = 0.5,           -- Scale of queue status button
                    Anchor = "BOTTOMLEFT", -- Anchor point
                    X = 2,                 -- X offset
                    Y = 80,                -- Y offset
                },
                BugSack = {                -- BugSack error counter button
                    Enabled = true,        -- Enable BugSack button skinning
                    Size = 15,             -- Size of button
                    Anchor = "BOTTOMLEFT", -- Anchor point
                    X = 2,                 -- X offset
                    Y = 2,                 -- Y offset
                },
            },

            -- MicroMenu Skinning
            MicroMenu = {
                Enabled = true,
                ButtonWidth = 23,
                ButtonHeight = 31,
                ButtonSpacing = -4,
                BackdropSpacing = 0,
                ShowBackdrop = true,
                BackdropColor = { 0, 0, 0, 0.8 },
                BackdropBorderColor = { 0, 0, 0, 1 },
                anchorFrameType = "SELECTFRAME",
                ParentFrame = "Minimap",
                Strata = "HIGH",
                Position = {
                    AnchorFrom = "TOP",
                    AnchorTo = "BOTTOM",
                    XOffset = 0,
                    YOffset = -1,
                },
                Mouseover = {
                    Enabled = false,
                    Alpha = 0.0,
                    FadeInDuration = 0.2,
                    FadeOutDuration = 0.2,
                },
            },

            -- Blizzard Element Mouseover
            BlizzardMouseover = {
                Enabled = true,       -- Master toggle for bags bar skinning
                Alpha = 0.0,          -- Alpha when not hovered (0 = fully hidden)
                FadeInDuration = 0.2, -- Fade in duration
                FadeOutDuration = 1,  -- Fade out duration
                BagMouseover = {
                    Enabled = true,   -- Enable mouseover fading
                },
            },

            -- Blizzard Messages Skinning
            BlizzardMessages = {
                Enabled = true,          -- Master toggle for Blizzard messages skinning
                -- Global font settings
                Font = "Expressway",     -- Font face
                FontOutline = "OUTLINE", -- Font outline
                -- UIErrorsFrame (red error messages at top of screen)
                UIErrorsFrame = {
                    Hide = false, -- Show/hide error messages
                    Size = 14,    -- Font size
                    -- Position
                    Position = {
                        Anchor = "TOP", -- Anchor point
                        X = 0,          -- X offset
                        Y = -281,       -- Y offset
                    },
                },
                -- ActionStatusText (action feedback messages)
                ActionStatusText = {
                    Hide = false, -- Show/hide action status messages
                    Size = 14,    -- Font size
                    -- Position
                    Position = {
                        Anchor = "TOP", -- Anchor point
                        X = 0,          -- X offset
                        Y = -251,       -- Y offset
                    },
                },
                -- Chat bubbles font
                ChatBubbles = {
                    Enabled = true, -- Enable chat bubble font skinning
                    Size = 8,       -- Font size
                },
                -- Objective tracker fonts
                ObjectiveTracker = {
                    Enabled = true,      -- Enable objective tracker font skinning
                    QuestTextSize = 12,  -- Font size for quest text
                    QuestTitleSize = 13, -- Font size for quest titles
                },
                ZoneText = {
                    Hide = false,
                    SubZone = {
                        Size = 20,
                    },
                    MainZone = {
                        Size = 40,
                        Anchor = "TOP", -- Anchor point
                        X = 0,          -- X offset
                        Y = -200,       -- Y offset
                    },
                },
            },

            -- UI Widgets Skinning (M+ timer, power bars, etc.)
            UIWidgets = {
                Enabled = true,
                Font = "Expressway",
                FontOutline = "OUTLINE",
                -- Status bar widgets (M+ timer, power bars)
                StatusBar = {
                    Enabled = true,
                    Width = 0,            -- Custom width (0 = use default)
                    StyleLabel = true,    -- Style the label above bars
                    StyleBarText = true,  -- Style text on the bar
                    LabelSize = 14,       -- Font size for labels
                    BarTextSize = 12,     -- Font size for bar text
                    StripTextures = true, -- Remove Blizzard textures and add backdrop
                    BackdropColor = { 0, 0, 0, 0.8 },
                    BorderColor = { 0, 0, 0, 1 },
                },
                -- Text widgets
                TextWidget = {
                    Enabled = true,
                    Width = 400, -- Custom width (0 = use default)
                    StyleText = true,
                    Size = 17,
                },
            },

            -- Tooltip Skinning
            Tooltips = {
                Enabled = true,
                Position = {
                    AnchorFrom = "BOTTOMRIGHT",
                    AnchorTo = "BOTTOMRIGHT",
                    XOffset = -1,
                    YOffset = 350,
                },
            },

            -- BuffTracking (SecureAuraHeader based buff display)
            BuffTracking = {
                Enabled = true,

                -- Icon settings
                IconSize = 36,
                IconSpacing = 1,
                IconsPerRow = 12,
                MaxRows = 5,
                IconZoom = 0.32,

                -- Visual settings
                BorderColor = { 0, 0, 0, 1 },
                BackgroundColor = { 0, 0, 0, 0.3 },
                EnchantBorderColor = { 0.6, 0, 1, 1 }, -- Purple for weapon enchants

                -- Font settings
                FontFace = "Expressway",
                FontSize = 13,
                FontOutline = "OUTLINE",
                TimerFontSize = 13,

                -- Timer text position (relative to icon)
                TimerPosition = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0,
                    YOffset = 1,
                },

                -- Position
                Strata = "MEDIUM",
                anchorFrameType = "SELECTFRAME",
                ParentFrame = "Minimap",
                Position = {
                    AnchorFrom = "TOPRIGHT",
                    AnchorTo = "TOPLEFT",
                    XOffset = -1,
                    YOffset = 0,
                },

                -- Filtering
                Filter = "HELPFUL",
                IncludeWeaponEnchants = true,
                SortMethod = "TIME",
                SortDirection = "-",
            },

            -- DebuffTracking (SecureAuraHeader based debuff display)
            DebuffTracking = {
                Enabled = true,

                -- Icon settings
                IconSize = 41,
                IconSpacing = 1,
                IconsPerRow = 12,
                MaxRows = 1,
                IconZoom = 0.32,

                -- Visual settings
                BorderColor = { 0.8, 0, 0, 1 },
                BackgroundColor = { 0, 0, 0, 0.3 },

                -- Font settings
                FontFace = "Expressway",
                FontSize = 14,
                FontOutline = "OUTLINE",
                TimerFontSize = 14,

                -- Timer text position (relative to icon)
                TimerPosition = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0,
                    YOffset = 0,
                },

                -- Position
                Strata = "MEDIUM",
                anchorFrameType = "SELECTFRAME",
                ParentFrame = "Minimap",
                Position = {
                    AnchorFrom = "TOPRIGHT",
                    AnchorTo = "BOTTOMLEFT",
                    XOffset = -1,
                    YOffset = 9,
                },

                -- Filtering
                SortMethod = "TIME",
                SortDirection = "-",
            },

            -- ExternalBuffTracking (External defensive buffs like Pain Suppression, Ironbark, etc.)
            ExternalBuffTracking = {
                Enabled = false,

                -- Icon settings
                IconSize = 52,
                IconSpacing = 1,
                IconsPerRow = 4,
                MaxRows = 1,
                IconZoom = 0.32,

                -- Visual settings
                BorderColor = { 0.2, 0.8, 0.2, 1 }, -- Green for externals
                BackgroundColor = { 0, 0, 0, 0.3 },

                -- Font settings
                FontFace = "Expressway",
                FontSize = 14,
                FontOutline = "OUTLINE",
                TimerFontSize = 18,

                -- Timer text position (relative to icon)
                TimerPosition = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0,
                    YOffset = 0,
                },

                -- Position
                Strata = "MEDIUM",
                anchorFrameType = "UIPARENT",
                ParentFrame = "UIParent",
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0,
                    YOffset = 200,
                },

                -- Sorting
                SortMethod = "TIME",
                SortDirection = "-",
            },

            -- Details Backdrop Settings
            DetailsBackdrop = {
                Enabled = true,
                detailsBarH = 26,
                detailsSpacing = 1,
                detailsTitelH = 20,
                detailsWidth = 260,
                backDropOne = {
                    Enabled = true,
                    autoSize = false,
                    detailsBars = 8,
                    width = 260,
                    height = 210,
                    BackgroundColor = { 0, 0, 0, 0.8 },
                    BorderColor = { 0, 0, 0, 1 },
                    anchorFrameType = "UIPARENT",
                    ParentFrame = "UIParent",
                    Strata = "LOW",
                    Position = {
                        AnchorFrom = "BOTTOMRIGHT",
                        AnchorTo = "BOTTOMRIGHT",
                        XOffset = -1,
                        YOffset = 1,
                    },
                },
                backDropTwo = {
                    Enabled = true,
                    autoSize = false,
                    detailsBars = 8,
                    width = 260,
                    height = 210,
                    BackgroundColor = { 0, 0, 0, 0.8 },
                    BorderColor = { 0, 0, 0, 1 },
                    anchorFrameType = "UIPARENT",
                    ParentFrame = "UIParent",
                    Strata = "LOW",
                    Position = {
                        AnchorFrom = "BOTTOMRIGHT",
                        AnchorTo = "BOTTOMRIGHT",
                        XOffset = -262,
                        YOffset = 1,
                    },
                },
            }
        },

        -- Instance Reset Message
        InstanceReset = {
            Enabled = true,
            Message = "Instance reset!",
        },

        -- Dungeon Timers (BigWigs Integration)
        DungeonTimers = {
            Enabled = true,

            -- Global display settings for Bars
            BarDisplay = {
                barWidth = 220,
                barHeight = 24,
                barTexture = "NorskenUI", -- LSM statusbar texture key
                fontFace = "Expressway",
                fontSize = 14,
                fontOutline = "OUTLINE", -- NONE, OUTLINE, THICKOUTLINE, SOFTOUTLINE
                iconEnabled = true,
            },

            -- Global display settings for Texts
            TextDisplay = {
                fontFace = "Expressway",
                fontSize = 24,
                fontOutline = "SOFTOUTLINE", -- NONE, OUTLINE, THICKOUTLINE, SOFTOUTLINE
                textAlign = "CENTER",        -- LEFT, CENTER, RIGHT
            },

            -- Global group settings (applies to all dungeons)
            BarGroup = {
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0,
                    YOffset = -128.1,
                },
                GrowthDirection = "UP",
                Spacing = 1,
            },
            TextGroup = {
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0.1,
                    YOffset = 75.1,
                },
                GrowthDirection = "DOWN",
                Spacing = 0,
            },

            -- Per-dungeon triggers (instanceId maps to BigWigs/LittleWigs boss modules)
            Dungeons = {
                MagistersTerrace  = { Enabled = true, instanceId = 2811, Triggers = {} },
                MaisaraCaverns    = { Enabled = true, instanceId = 2874, Triggers = {} },
                NexusPointXenas   = { Enabled = true, instanceId = 2915, Triggers = {} },
                WindrunnerSpire   = { Enabled = true, instanceId = 2805, Triggers = {} },
                AlgetharAcademy   = { Enabled = true, instanceId = 2526, Triggers = {} },
                PitOfSaron        = { Enabled = true, instanceId = 658, Triggers = {} },
                SeatOfTriumvirate = { Enabled = true, instanceId = 1753, Triggers = {} },
                Skyreach          = { Enabled = true, instanceId = 1209, Triggers = {} },
            },

            -- Default values for new triggers (template)
            -- Per-trigger defaults (text content, colors)
            TriggerDefaults = {
                enabled = true,
                triggerType = "timer",
                spellId = "",
                message = "",
                messageOperator = "find",
                remainingEnabled = true,
                remainingOperator = "<=",
                remainingValue = 5,
                countEnabled = false,
                countOperator = "==",
                countValue = 1,
                extendTimer = 0,
                displayType = "bar",
                -- Colors
                useBigWigsColors = true,
                barColor = { 0.772, 0.168, 0.168, 1 },
                backgroundColor = { 0.1, 0.1, 0.1, 0.8 },
                textColor = { 1, 1, 1, 1 },
                -- Bar text settings
                barText1Format = "Tank Hit",
                barText1Justify = "LEFT",
                barText1XOffset = 3,
                barText1YOffset = 0,
                barText2Format = "%p",
                barText2Justify = "RIGHT",
                barText2XOffset = -3,
                barText2YOffset = 0,
                -- Text mode settings
                textFormat = "%n » %p",
                textJustify = "LEFT",
                showDecimals = true,
                decimalThreshold = 1,
                -- Custom text (Lua code for %c placeholder)
                -- Function signature: function(expirationTime, duration, remaining, name, icon, stacks)
                customText = "",
                -- Load conditions
                loadRoleEnabled = false,
                loadRoleTank = true,
                loadRoleHealer = true,
                loadRoleDPS = true,
                -- Actions
                actionOnShowSound = "None",
                actionOnHideSound = "None",
            },
        },

        -- Dungeon Casts (Enemy Nameplate Casting Monitor)
        DungeonCasts = {
            Enabled = true,

            -- Frame settings
            Frame = {
                MaxBars = 5,
                Width = 265,
                Height = 28,
                Spacing = 1,
                GrowthDirection = "UP", -- UP or DOWN
                Strata = "HIGH",
                anchorFrameType = "UIPARENT",
                ParentFrame = "UIParent",
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = -360.1,
                    YOffset = 90.1,
                },
            },

            -- Bar appearance
            BarDisplay = {
                StatusBarTexture = "NorskenUI",
                FontFace = "Expressway",
                FontSize = 13,
                FontOutline = "OUTLINE",
                SparkEnabled = false,
            },

            -- Icon settings
            Icon = {
                Enabled = true,
                Size = 28,
                Zoom = 0.3,
            },

            -- Colors
            CastingColor = { 0.623, 0.749, 1.0, 1 },
            ChannelingColor = { 0.8, 0.4, 1.0, 1 },
            NotInterruptibleColor = { 0.780, 0.250, 0.250, 1 },
            BackgroundColor = { 0, 0, 0, 0.8 },
            BorderColor = { 0, 0, 0, 1 },

            -- Raid target icon
            RaidIcon = {
                Enabled = true,
                Size = 21,
            },

            -- Text settings
            Text = {
                NameAlign = "LEFT",
                TimeAlign = "RIGHT",
                ShowTime = true,
                TextColor = { 1, 1, 1, 1 },
            },

            -- Target display settings
            Target = {
                Enabled = true,
                ShowClassColor = true,
                Position = "LEFT", -- LEFT or RIGHT
                Separator = "»",   -- Separator between spell name and target
            },
        },

        -- Missing Buffs Tracker
        MissingBuffs = {
            -- General Settings
            Enabled = true, -- Enable/disable module
            -- Consumable Tracking
            Consumables = {
                Flask = { Enabled = true, LoadCondition = "ANYGROUP" },
                Food = { Enabled = true, LoadCondition = "ANYGROUP" },
                MHEnchant = { Enabled = true, LoadCondition = "ANYGROUP" },
                OHEnchant = { Enabled = true, LoadCondition = "ANYGROUP" },
                Rune = { Enabled = true, LoadCondition = "RAID" },
                RaidBuffs = { Enabled = true, LoadCondition = "ANYGROUP" },
                Poisons = { Enabled = true, LoadCondition = "ALWAYS" },
            },
            -- Raid Buff Display Settings (separate position from main)
            RaidBuffDisplay = {
                IconSize = 48,
                IconSpacing = 1,
                FontFace = "Expressway",     -- Font face
                FontSize = 20,               -- Font size
                FontOutline = "SOFTOUTLINE", -- Font outline
                Strata = "HIGH",
                anchorFrameType = "UIPARENT",
                ParentFrame = "UIParent",
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0,
                    YOffset = -380,
                },
            },
            -- Stance & Spec Buff Settings
            Stances = {
                Enabled = true, -- Master toggle for stance tracking
                -- Warrior Stances
                WARRIOR = {
                    Enabled = true,            -- Warn if no stance active
                    ArmsEnabled = true,        -- Require specific stance for Arms
                    Arms = "386164",           -- Battle Stance
                    ArmsReverseIcon = true,    -- Show current stance icon instead of required
                    FuryEnabled = true,        -- Require specific stance for Fury
                    Fury = "386196",           -- Berserker Stance
                    FuryReverseIcon = true,
                    ProtectionEnabled = false, -- Require specific stance for Protection
                    Protection = "386208",     -- Defensive Stance
                    ProtectionReverseIcon = false,
                },

                -- Paladin Auras
                PALADIN = {
                    Enabled = true,
                    HolyEnabled = false,
                    Holy = "465", -- Devotion Aura
                    HolyReverseIcon = false,
                    ProtectionEnabled = false,
                    Protection = "465", -- Devotion Aura
                    ProtectionReverseIcon = false,
                    RetributionEnabled = false,
                    Retribution = "32223", -- Crusader Aura
                    RetributionReverseIcon = false,
                },

                -- Druid Forms
                DRUID = {
                    Enabled = true,
                    BalanceEnabled = true,
                    Balance = "24858", -- Moonkin Form
                    BalanceReverseIcon = false,
                    BalanceCombatOnly = false,
                    FeralEnabled = true,
                    Feral = "768", -- Cat Form
                    FeralReverseIcon = false,
                    FeralCombatOnly = false,
                    GuardianEnabled = true,
                    Guardian = "5487", -- Bear Form
                    GuardianReverseIcon = false,
                    GuardianCombatOnly = false,
                },

                -- Priest Shadowform
                PRIEST = {
                    ShadowEnabled = true, -- Require Shadowform for Shadow spec
                    ShadowReverseIcon = false,
                },

                -- Evoker Attunements
                EVOKER = {
                    Enabled = true,
                    AugmentationEnabled = false,
                    Augmentation = "403264", -- Black Attunement
                    AugmentationReverseIcon = false,
                },
            },

            -- Stance Display Settings (separate position)
            StanceDisplay = {
                Enabled = true,              -- Enable stance text display
                IconSize = 36,
                FontFace = "Expressway",     -- Font face
                FontSize = 13,               -- Font size
                FontOutline = "SOFTOUTLINE", -- Font outline
                Strata = "HIGH",
                anchorFrameType = "UIPARENT",
                ParentFrame = "UIParent",
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = 0,
                    YOffset = -110,
                },
            },

            -- Stance Text Display Settings
            StanceText = {
                Enabled = false, -- Enable stance text display
                FontFace = "Expressway",
                FontSize = 14,
                FontOutline = "SOFTOUTLINE",
                Strata = "HIGH",
                anchorFrameType = "UIPARENT",
                ParentFrame = "UIParent",
                Position = {
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    XOffset = -250,
                    YOffset = -130,
                },

                -- Warrior Stance Texts
                WARRIOR = {
                    ["386164"] = { Enabled = true, Text = "BATTLE", Color = { 1, 0, 0, 1 } },
                    ["386196"] = { Enabled = true, Text = "BER", Color = { 1, 0, 0, 1 } },
                    ["386208"] = { Enabled = true, Text = "DEF", Color = { 0.3, 0.7, 1, 1 } },
                },

                -- Paladin Aura Texts
                PALADIN = {
                    ["465"] = { Enabled = true, Text = "DEVO", Color = { 0.3, 0.7, 1, 1 } },
                    ["317920"] = { Enabled = true, Text = "CONC", Color = { 0.9, 0.5, 1, 1 } },
                    ["32223"] = { Enabled = true, Text = "CRU", Color = { 1, 0.8, 0.3, 1 } },
                },
            },

            -- Custom buffs to track (spellId based)
            CustomBuffs = {
            },
        },
    },
}

-- Returns the Default Table.
function NRSKNUI:GetDefaultDB()
    return Defaults
end

-- Position Card Template
--[[

                anchorFrameType = "UIPARENT",
                ParentFrame = "UIParent",
                Strata = "LOW",
                Position = {
                    AnchorFrom = "BOTTOMRIGHT",
                    AnchorTo = "BOTTOMRIGHT",
                    XOffset = -1,
                    YOffset = 1,
                },

]]
