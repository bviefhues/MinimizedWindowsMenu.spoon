--- === MinimizedWindowsMenu ===
---
--- Menubar menu for showing and switching to minimized windows.
--- Shows windows of the current space only.

local spaces =     require("hs._asm.undocumented.spaces")
local inspect =    require("hs.inspect")
local window =     require("hs.window")
local fnutils =    require("hs.fnutils")
local spoons =     require("hs.spoons")
local image =      require("hs.image")
local menubar =    require("hs.menubar")

local obj={}
obj.__index = obj

-- Metadata
obj.name = "MinimizedWindowsMenu"
obj.version = "0.0"
obj.author = "B Viefhues"
obj.homepage = "https://github.com/bviefhues/MinimizedWindowsMenu.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"


--- MinimizedWindowsMenu.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set 
--- the default log level for the messages coming from the Spoon.
obj.log = hs.logger.new("MinimizedWindowsMenu")

-- Internal: MinimizedWindowsMenu.menubar
-- Variable
-- Contains the Spoons hs.menubar.
obj.menubar = nil

-- Internal: MinimizedWindowsMenu.appIconCache
-- Variable
-- Dict for caching app icon per app name.
obj.appIconCache = {}

-- Internal: MinimizedWindowsMenu.menubarIcon
-- Variable
-- The menubar icon.
obj.menubarIcon = [[ASCII:
. . . . . . . . . . . . . . . . . . . .
. . h a # # # # # # # # # # # # a b . .
. h i # # # # # # # # # # # # # # i b .
. g . . . . . . . . . . . . . . . . c .
. # . . . . . . . . . . . . . . . . # .
. # . . . . . . E # # # E F . . . . # .
. # . . . . . . . . . . . # . . . . # .
. # . . . . C # # C D . . # . . . . # .
. # . . . . . . . . # . . # . . . . # .
. g . . A # A B . . # . . F . . . . # .
. . . . . . . # . . D . . . . . . . # .
. 4 # # 3 . . B . . . . . . . . . . c .
. # # # # . . . . . . . . . . . . . d .
. 1 # # 2 . e # # # # # # # # # e d . .
. . . . . . . . . . . . . . . . . . . .
]]

-- Internal: Utility function to debug windows states
function logWindows(text, windows)
    obj.log.d(text)
    for i, w in ipairs(windows) do
        obj.log.d("  ", i, 
            "ID:"..w:id(), 
            "V:"..tostring(w:isVisible()):sub(1,1), 
            "S:"..tostring(w:isStandard()):sub(1,1), 
            "M:"..tostring(w:isMinimized()):sub(1,1),
            "("..w:title():sub(1,25)..")")
    end
end

-- Internal: Make window visible by unminimizing, raising and focussing
function obj.makeWindowVisible(modifiers, menuItem)
    obj.log.d("> makeWindowVisible", 
        inspect(modifiers), inspect(menuItem))
    menuItem.window:unminimize():raise():focus()
    obj.log.d("< makeWindowVisible")
end

-- Internal: Get the application icon for a window
-- Caches the generated app icons, per application name
function obj.iconForWindow(window)
    local application = window:application()
    obj.log.d("> iconForWindow()", window:title(), application:name())
    
    obj.log.d("Getting cached app icon")
    local icon = obj.appIconCache[application:name()]
    if not icon then
        obj.log.d("Getting icon from imageFromAppBundle()")
        icon = image.imageFromAppBundle(application:bundleID())
        icon = icon:copy():size({w=16,h=16})
        obj.appIconCache[application:name()] = icon
    end

    obj.log.d("< iconForWindow()")
    return icon
end


-- Internal: Generates the menu table for the menu bar.
-- Will be dunamically evaluated each time the menu is displayed.
function obj.menuTable()
    obj.log.d("> menuTable")
    local menuTable = {}
    for _, w in ipairs(window.minimizedWindows()) do
        -- filter for windows in current space
        if fnutils.contains(w:spaces(), spaces.activeSpace()) then
            table.insert(menuTable, {
                title = w:title(),  
                image = obj.iconForWindow(w), -- window app icon
                fn = obj.makeWindowVisible,
                window = w, -- remember window object to process in fn
            })
        end
    end

    if #menuTable == 0 then -- no minimized windows
        menuTable = {{
            title = "(none)",
            disabled = true,
        }}
    end

    -- obj.log.d("< menuTable ->", inspect.inspect(menuTable))
    obj.log.d("< menuTable ->", "(...)")
    return menuTable
end

-- Internal for the time being, leaving in in case keybeindings added later
-- MinimizedWindowsMenu:bindHotkeys(mapping)
-- Method
-- Binds hotkeys for MinimizedWindowsMenu
--
-- Parameters:
--  * mapping - A table containing hotkey modifier/key details for 
--     the following items:
--   * 
--
-- Returns:
--  * The MinimizedWindowsMenu object
function obj:bindHotkeys(mapping)
    obj.log.d("> bindHotkeys", inspect(mapping))
    local def = {
    }
    spoons.bindHotkeysToSpec(def, mapping)
    obj.log.d("< bindHotkeys")
    return self
end

--- MinimizedWindowsMenu:start()
--- Method
--- Starts MinimizedWindowsMenu spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The MinimizedWindowsMenu object
function obj:start()
    obj.log.d("> start")
    obj.menubar = menubar.new()
    obj.menubar:setIcon(obj.menubarIcon)
    obj.menubar:setMenu(obj.menuTable)
    obj.log.d("< start")
    return self
end

--- MinimizedWindowsMenu:stop()
--- Method
--- Stops MinimizedWindowsMenu spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The MinimizedWindowsMenu object
function obj:stop()
    obj.log.d("> stop")
    if obj.menubar then obj.menubar:delete() end
    obj.menubar = nil
    obj.log.d("< stop")
    return self
end

--- MinimizedWindowsMenu:setLogLevel()
--- Method
--- Set the log level of the spoon logger.
--- Utility method for chaining.
---
--- Parameters:
---  * Log level 
---
--- Returns:
---  * The MinimizedWindowsMenu object
function obj:setLogLevel(level)
    obj.log.d("> setLogLevel")
    obj.log.setLogLevel(level)
    obj.log.d("< setLogLevel")
    return self
end

return obj
