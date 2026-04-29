---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame

GUIFrame.SidebarConfig = {
    systems = {
        {
            id = "profiles_section",
            type = "header",
            text = "Profiles",
            defaultExpanded = false,
            items = {
                { id = "ProfileManager", text = "Profile Manager" },
            }
        },
        {
            id = "combat_section",
            type = "header",
            text = "Combat Util",
            defaultExpanded = false,
            items = {
                { id = "combatTimer",          text = "Combat Timer" },
                { id = "combatCross",          text = "Combat Cross" },
                { id = "battleRes",            text = "Combat Res" },
                { id = "combatMessage",        text = "Combat Texts" },
                { id = "cursorCircle",         text = "Cursor Circle" },
                { id = "FocusCastbar",         text = "Focus Castbar" },
                { id = "RangeChecker",         text = "Range Checker Text" },
                { id = "TimeSpiral",           text = "Time Spiral" },
                { id = "CustomSkin_Externals", text = "External & Defensive Buffs" },
            }
        },
        {
            id = "missingBuffs_section",
            type = "header",
            text = "Missing Buffs & Stances",
            defaultExpanded = false,
            items = {
                { id = "missingBuffs", text = "Missing Buffs" },
            }
        },
        {
            id = "miscellaneous_section",
            type = "header",
            text = "Class Util",
            defaultExpanded = false,
            items = {
                { id = "IncarnStacks", text = "Guardian Druid: Incarn Stacks" },
                { id = "HuntersMark",  text = "Hunter: Mark Missing" },
                { id = "PetTexts",     text = "Pet Status Texts" },
                { id = "gateway",      text = "Gateway Alert" },
            }
        },
        {
            id = "qol_section",
            type = "header",
            text = "Quality of Life",
            defaultExpanded = false,
            items = {
                { id = "MiscVars",           text = "CVars" },
                { id = "Automation",         text = "Automation" },
                { id = "CopyAnything",       text = "Copy Anything" },
                { id = "CooldownStrings",    text = "CDM Profile Strings" },
                { id = "whisperSounds",      text = "Whisper Sounds" },
                { id = "DragonRiding",       text = "Dragon Riding UI" },
                { id = "XPBar",              text = "XP Bar" },
                { id = "Durability",         text = "Durability Util" },
                { id = "AuctionHouseFilter", text = "AH Current Expansion Filter" },
                { id = "Recuperate",         text = "Recuperate Button" },
            }
        },
        {
            id = "skinning_section",
            type = "header",
            text = "Skinning",
            defaultExpanded = false,
            elvUIDisabled = true,
            items = {
                { id = "CustomSkin_Buffs",   text = "Buffs" },
                { id = "CustomSkin_Debuffs", text = "Debuffs" },
                { id = "UICleanup",          text = "General UI Cleanup" },
                { id = "Chat",               text = "Chat" },
                { id = "ActionBars",         text = "Action Bars" },
                { id = "Minimap",            text = "Minimap" },
                { id = "MicroMenu",          text = "Micro Menu" },
                { id = "BlizzardMouseover",  text = "Blizzard Mouseover" },
                { id = "messages",           text = "Blizzard Texts" },
                { id = "tooltips",           text = "Tooltips" },
                { id = "DetailsBackdrop",    text = "Details Backdrop" },
                { id = "BlizzardRM",         text = "Raid Manager" },
                { id = "UIWidgets",          text = "UI Widgets" },
            }
        },
        {
            id = "dungeons_section",
            type = "header",
            text = "Dungeon & Party Util",
            defaultExpanded = false,
            items = {
                { id = "InstanceReset", text = "Instance Reset" },
                { id = "HealerMana",    text = "Healer Mana" },
                { id = "DungeonCasts",  text = "Dungeon Casts" },
            }
        },
        {
            id = "bigwigs_section",
            type = "header",
            text = "BigWigs Timers",
            defaultExpanded = false,
            items = {
                { id = "DT_General",                text = "General" },
                { id = "DT_Bars",                   text = "Bar Settings" },
                { id = "DT_Texts",                  text = "Text Settings" },
                { id = "Dungeon_MagistersTerrace",  text = "Magisters' Terrace" },
                { id = "Dungeon_MaisaraCaverns",    text = "Maisara Caverns" },
                { id = "Dungeon_NexusPointXenas",   text = "Nexus-Point Xenas" },
                { id = "Dungeon_WindrunnerSpire",   text = "Windrunner Spire" },
                { id = "Dungeon_AlgetharAcademy",   text = "Algeth'ar Academy" },
                { id = "Dungeon_PitOfSaron",        text = "Pit of Saron" },
                { id = "Dungeon_SeatOfTriumvirate", text = "Seat of the Triumvirate" },
                { id = "Dungeon_Skyreach",          text = "Skyreach" },
            }
        },
    },
}
