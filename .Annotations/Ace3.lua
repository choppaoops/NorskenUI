---@meta

---@class AceEvent-3.0
---@field RegisterEvent fun(self: any, event: string, callbackOrMethod?: string|function)
---@field UnregisterEvent fun(self: any, event: string)
---@field UnregisterAllEvents fun(self: any)

---@class AceModule
---@field db table
---@field ApplyPosition fun(self: AceModule)
---@field ApplySettings fun(self: AceModule)
---@field RefreshPanel fun(self: AceModule)
---@field GetSpecInfoByID fun(specID: number): table?
---@field ApplyProfileToCDM fun(profileString: string, profileKey: string, callbacks?: table): boolean
---@field IsEnabled fun(self: AceModule): boolean
---@field SetEnabledState fun(self: AceModule, state: boolean)
---@field GetName fun(self: AceModule): string

---@class AceHook-3.0
local AceHook = {}

---@param objectOrFuncName table|string
---@param methodOrHandler? string|function
---@param handler? function
function AceHook:SecureHook(objectOrFuncName, methodOrHandler, handler) end

---@param frame Frame
---@param script string
---@param handler? function
function AceHook:SecureHookScript(frame, script, handler) end

---@param objectOrFuncName table|string
---@param method? string
function AceHook:Unhook(objectOrFuncName, method) end

function AceHook:UnhookAll() end

---@param objectOrFuncName table|string
---@param method? string
---@return boolean
function AceHook:IsHooked(objectOrFuncName, method) end

---@param objectOrFuncName table|string
---@param methodOrHandler? string|function
---@param handler? function
function AceHook:RawHook(objectOrFuncName, methodOrHandler, handler) end

---@param objectOrFuncName table|string
---@param methodOrHandler? string|function
---@param handler? function
function AceHook:Hook(objectOrFuncName, methodOrHandler, handler) end

---@class AceAddon-3.0
---@field NewModule fun(self: AceAddon-3.0, name: string, ...: string): AceModule
---@field GetModule fun(self: AceAddon-3.0, name: string, silent?: boolean): AceModule?
---@field EnableModule fun(self: AceAddon-3.0, name: string)
---@field DisableModule fun(self: AceAddon-3.0, name: string)
---@field IterateModules fun(self: AceAddon-3.0): fun(): string, AceModule
---@field GetName fun(self: AceAddon-3.0): string
---@field SetDefaultModuleLibraries fun(self: AceAddon-3.0, ...: string)
---@field SetDefaultModuleState fun(self: AceAddon-3.0, state: boolean)
---@field SetDefaultModulePrototype fun(self: AceAddon-3.0, prototype: table)
---@field SetEnabledState fun(self: AceAddon-3.0, state: boolean)
---@field IsEnabled fun(self: AceAddon-3.0): boolean
---@field ApplySettings fun(self: AceAddon-3.0)
---@field UpdateDB fun(self: AceAddon-3.0)
