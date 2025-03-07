local t = component.proxy(component.list("transposer")())

-- Cache global functions for faster access
local ipairs = ipairs
local uptime, pullSignal = computer.uptime, computer.pullSignal
local getInventoryName, getTankCount, getAllStacks, getFluidInTank, transferItem =
    t.getInventoryName,
    t.getTankCount,
    t.getAllStacks,
    t.getFluidInTank,
    t.transferItem

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

local ncs, disks, tanks, fluid, target
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
                    -- This check is very cursed, just trust that longer NBT data means fluid is present.
                    -- No longer required on versions >= 2.7.3.
                    if #disks[2].tag > 48 then fluid = true end
                -- Otherwise, check the fluid hatch next to the transposer, if present.
                elseif hatch then
                    tanks = getFluidInTank(hatch)
                    for i = 1, #tanks do
                        if tanks[i].amount > 0 then fluid = true break end
                    end
                end
                -- Move the non-consumed item if no more fluids present.
                if not fluid then
                    for i, _ in ipairs(ncs) do
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
