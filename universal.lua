local transposer = component.proxy(component.list("transposer")())

-- Cache global functions for faster access
local ipairs           = ipairs
local assert           = assert
local uptime           = computer.uptime
local pullSignal       = computer.pullSignal
local getInventoryName = transposer.getInventoryName
local getTankCount     = transposer.getTankCount
local getAllStacks     = transposer.getAllStacks
local getFluidInTank   = transposer.getFluidInTank
local transferItem     = transposer.transferItem

local hatch, nc, drive, interface
for side = 0, 5 do
    local n = getInventoryName(side)
    if n == "gt.blockmachines" and getTankCount(side) > 0 then hatch = side
    elseif n == "tile.extrautils:chestFull" or n == "tile.etfuturum.barrel" then nc = side
    elseif n == "tile.appliedenergistics2.BlockDrive" then drive = side
    elseif not n then
        -- This call must succeed. Only a tile entity that can actually receive items passes this.
        if pcall(transferItem, side, side, 0, 1, 1) then
            interface = side
        end
    end
end

-- Ensure required components were found
assert(       nc, "Error: No NC inventory found.")
assert(    drive, "Error: No drive found.")
assert(interface, "Error: No interface found.")

local ncs, disks, fluid, target, storedTypes
while true do
    ncs = getAllStacks(nc)
    -- We may need to circuit switch if there is a non-consumed item.
    if ncs[1] then
        while true do
            disks = getAllStacks(drive)
            -- If there are no more items to process, check if there are fluids remaining.
            if disks[1].storedItemTypes == 0 then
                fluid = false
                -- If using a fluid storage cell, we are using an advanced stocking hatch.
                if disks[2] then
                    storedTypes = disks[2].storedFluidTypes
                    fluid = storedTypes and storedTypes > 0 or not storedTypes and #disks[2].tag > 48
                -- Otherwise, check the fluid hatch next to the transposer, if present.
                elseif hatch then
                    for _, tank in ipairs(getFluidInTank(hatch)) do
                        if tank.amount > 0 then fluid = true break end
                    end
                end
                -- Move the non-consumed item if no more fluids present.
                if not fluid then
                    for i in ipairs(ncs) do
                        while transferItem(nc, interface, 1, i, (i + interface - 1) % 9 + 1) == 0 do end
                    end
                    break
                end
            end
            target = uptime() + 0.40
            while uptime() < target do pullSignal(0) end
        end
    end
    target = uptime() + 0.35
    while uptime() < target do pullSignal(0) end
end
