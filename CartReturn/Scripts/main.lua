--[[
    Cart Return - Abiotic Factor UE4SS mod

    Recalls Platform Carts to the player. The cart actor itself is moved, so
    its inventory comes along untouched.

    Default keys (see CONFIG):
        F6  recall the nearest cart
        F7  recall every loaded cart
        F8  scan: log cart classes and candidate native functions
]]

local UEHelpers = require("UEHelpers")

local VERSION = "1.1.0"
local TAG = "[CartReturn]"

--------------------------------------------------------------------- config --

local CONFIG = {
    -- Names from the UE4SS `Key` table.
    KEY_RECALL_NEAREST = "F6",
    KEY_RECALL_ALL     = "F7",
    KEY_SCAN           = "F8",

    -- Base class of all deployables. Searched first, then filtered by CART_MATCH.
    DEPLOYABLE_PARENT = "AbioticDeployed_ParentBP_C",

    -- Exact cart class names. Searched directly when the parent search finds
    -- no carts. Add the name reported by the scan here once confirmed.
    CART_CLASSES = {
        -- "Deployed_PlatformCart_C",
    },

    -- Case-insensitive substrings; a class whose name contains any of these
    -- is treated as a cart.
    CART_MATCH = { "platformcart" },

    -- Placement relative to the player, in Unreal units (100 = 1 m).
    FORWARD_OFFSET = 200.0, -- distance in front of the player
    HEIGHT_OFFSET  = 60.0,  -- lift above the player's origin to avoid clipping the floor
    SPREAD         = 140.0, -- side-to-side spacing when recalling several carts

    -- Clear leftover physics velocity after moving a cart.
    ZERO_VELOCITY = true,

    -- Substrings the scan looks for in function names on the cart class chain.
    PROBE_FUNCS = { "package", "recall", "pickup", "pack", "return", "redeploy", "deploy" },
}

-------------------------------------------------------------------- helpers --

local function log(fmt, ...)
    print(TAG .. " " .. string.format(fmt, ...))
end

-- Calls fn, returning its result or nil if it raised.
local function try(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

local function isValid(obj)
    return obj ~= nil and try(function() return obj:IsValid() end) == true
end

local function nameOf(obj)
    return try(function() return obj:GetFName():ToString() end) or ""
end

local function classNameOf(actor)
    local cls = try(function() return actor:GetClass() end)
    return cls and nameOf(cls) or ""
end

local function containsAny(haystack, needles)
    local lower = haystack:lower()
    for _, needle in ipairs(needles) do
        if lower:find(needle:lower(), 1, true) then return true end
    end
    return false
end

local function findAllOf(className)
    local found = try(function() return FindAllOf(className) end)
    return type(found) == "table" and found or {}
end

local function distSq(a, b)
    local dx, dy, dz = a.X - b.X, a.Y - b.Y, a.Z - b.Z
    return dx * dx + dy * dy + dz * dz
end

---------------------------------------------------------------------- carts --

local exactCartClass = {}
for _, name in ipairs(CONFIG.CART_CLASSES) do exactCartClass[name] = true end

local function isCartClass(name)
    return exactCartClass[name] or containsAny(name, CONFIG.CART_MATCH)
end

local function getPawn()
    local pc = UEHelpers.GetPlayerController()
    if not isValid(pc) then return nil end
    local pawn = pc:K2_GetPawn()
    return isValid(pawn) and pawn or nil
end

-- All loaded cart actors, deduplicated.
local function findCarts()
    local carts, seen = {}, {}

    local function add(actor)
        if not isValid(actor) or not isCartClass(classNameOf(actor)) then return end
        local addr = actor:GetAddress()
        if not seen[addr] then
            seen[addr] = true
            carts[#carts + 1] = actor
        end
    end

    for _, actor in ipairs(findAllOf(CONFIG.DEPLOYABLE_PARENT)) do add(actor) end
    if #carts == 0 then
        for _, cls in ipairs(CONFIG.CART_CLASSES) do
            for _, actor in ipairs(findAllOf(cls)) do add(actor) end
        end
    end
    return carts
end

local function nearestTo(origin, actors)
    local best, bestDist
    for _, actor in ipairs(actors) do
        local d = distSq(actor:K2_GetActorLocation(), origin)
        if not bestDist or d < bestDist then best, bestDist = actor, d end
    end
    return best
end

local function hasAuthority(actor)
    -- Assume authority if the call isn't available (e.g. single-player quirks).
    local result = try(function() return actor:HasAuthority() end)
    return result ~= false
end

-- Target for slot `index` (0-based) of `count`: a row centred in front of the
-- player, perpendicular to their facing. Rotation is yaw-only so carts stay level.
local function slotTransform(pawn, index, count)
    local loc = pawn:K2_GetActorLocation()
    local yawDeg = pawn:K2_GetActorRotation().Yaw
    local yaw = math.rad(yawDeg)
    local fx, fy = math.cos(yaw), math.sin(yaw) -- forward
    local rx, ry = -fy, fx                      -- right
    local lateral = (index - (count - 1) / 2) * CONFIG.SPREAD

    loc.X = loc.X + fx * CONFIG.FORWARD_OFFSET + rx * lateral
    loc.Y = loc.Y + fy * CONFIG.FORWARD_OFFSET + ry * lateral
    loc.Z = loc.Z + CONFIG.HEIGHT_OFFSET
    return loc, { Pitch = 0.0, Yaw = yawDeg, Roll = 0.0 }
end

local function zeroVelocity(cart)
    local root = try(function() return cart:K2_GetRootComponent() end)
    if not isValid(root) then return end
    local zero = { X = 0.0, Y = 0.0, Z = 0.0 }
    try(function() root:SetPhysicsLinearVelocity(zero, false, FName("None")) end)
    try(function() root:SetPhysicsAngularVelocityInDegrees(zero, false, FName("None")) end)
end

local function moveCart(cart, location, rotation)
    -- K2_TeleportTo returns false when the destination is blocked.
    local moved = try(function() return cart:K2_TeleportTo(location, rotation) end) == true
    if not moved then
        -- bSweep = false, bTeleport = true. Only an explicit false counts as failure.
        local ok, result = pcall(function()
            return cart:K2_SetActorLocationAndRotation(location, rotation, false, {}, true)
        end)
        moved = ok and result ~= false
    end
    if moved and CONFIG.ZERO_VELOCITY then zeroVelocity(cart) end
    return moved
end

-------------------------------------------------------------------- actions --

local function recallCarts(nearestOnly)
    local pawn = getPawn()
    if not pawn then
        log("No player pawn; load into a game first.")
        return
    end

    local carts = findCarts()
    if #carts == 0 then
        log("No carts found. Press %s to scan for the cart class name.", CONFIG.KEY_SCAN)
        return
    end
    if nearestOnly then
        carts = { nearestTo(pawn:K2_GetActorLocation(), carts) }
    end

    local warnedAuthority = false
    local moved = 0
    for i, cart in ipairs(carts) do
        if not warnedAuthority and not hasAuthority(cart) then
            log("Warning: not the host; moves may not replicate to other players.")
            warnedAuthority = true
        end
        local location, rotation = slotTransform(pawn, i - 1, #carts)
        if moveCart(cart, location, rotation) then
            moved = moved + 1
        else
            log("Failed to move %s.", classNameOf(cart))
        end
    end
    log("Recalled %d of %d cart(s).", moved, #carts)
end

-- Logs the class chain of `cls` up to Actor, with any functions matching PROBE_FUNCS.
local function probeClassChain(cls)
    local depth = 0
    while isValid(cls) and depth < 16 do
        local indent = string.rep("  ", depth)
        local name = nameOf(cls)
        log("    %s%s", indent, name)

        try(function()
            cls:ForEachFunction(function(fn)
                local fnName = nameOf(fn)
                if containsAny(fnName, CONFIG.PROBE_FUNCS) then
                    log("    %s  fn: %s", indent, fnName)
                end
            end)
        end)

        if name == "Actor" then break end
        cls = try(function() return cls:GetSuperStruct() end)
        depth = depth + 1
    end
end

local function scan()
    log("---- scan ----")

    local carts = findCarts()
    log("Matched %d cart(s) (CART_MATCH: %s).", #carts, table.concat(CONFIG.CART_MATCH, ", "))

    local probed = {}
    for _, cart in ipairs(carts) do
        local name = classNameOf(cart)
        log("  Found cart: %s", name)
        if not probed[name] then
            probed[name] = true
            log("  Class chain and candidate functions:")
            probeClassChain(cart:GetClass())
        end
    end

    local pool = findAllOf(CONFIG.DEPLOYABLE_PARENT)
    log("%d actor(s) of %s.", #pool, CONFIG.DEPLOYABLE_PARENT)
    if #pool == 0 then
        log("Parent class matched nothing; searching all actors (slow).")
        pool = findAllOf("Actor")
    end

    log("Class names containing 'cart':")
    local listed = {}
    for _, actor in ipairs(pool) do
        local name = isValid(actor) and classNameOf(actor) or ""
        if not listed[name] and name:lower():find("cart", 1, true) then
            listed[name] = true
            log("  - %s%s", name, isCartClass(name) and "  [matched]" or "")
        end
    end
    if next(listed) == nil then
        log("  (none) Try UE4SS Live View and search for 'Cart'.")
    end

    log("---- end scan ----")
end

------------------------------------------------------------------- keybinds --

local function bind(keyName, action)
    local key = Key[keyName]
    if key == nil then
        log("Unknown key '%s'; binding skipped.", keyName)
        return
    end
    RegisterKeyBind(key, function() ExecuteInGameThread(action) end)
end

bind(CONFIG.KEY_RECALL_NEAREST, function() recallCarts(true) end)
bind(CONFIG.KEY_RECALL_ALL, function() recallCarts(false) end)
bind(CONFIG.KEY_SCAN, scan)

log("v%s loaded. %s: nearest cart, %s: all carts, %s: scan.",
    VERSION, CONFIG.KEY_RECALL_NEAREST, CONFIG.KEY_RECALL_ALL, CONFIG.KEY_SCAN)
