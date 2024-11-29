-- UnlockCmd: Unlock chars via commands in the select screen.
-- Version: 1.0
-- Date: 11/26/2024
-- Author: Rakíel
-- Compatible with: Ikemen GO v0.99 and nightly
-- Description: This mod lets you create special commands to unlock chars in the select screen. These commands are defined in the unlockCmdConfig.json file.
-- To use this mod, you must declare specific parameters inside the unlockCmdConfig.json file. After that, you can call the commands in the select.def.
--
-- unlockConfig.json parameters:
-- * name: The name of the char to be unlocked with the command. It must match exactly how it is written in select.def, e.g., "kfm".
-- * command: Write here the command to unlock the char (in the same format as commands are written in the char's CMD file), e.g., "~F,F,F,B,B,s".
-- * holdstart: If set to 1, the command requires holding the start button to execute.
-- * unlocked: If set to true, the char will be unlocked by default.
-- * unlocksnd: Group, index and volume of the sound to be played when the command is executed. Sounds must be added to unlockCmdSounds.snd, e.g., "1,0,100".
-- * hidden: If true, the cell will remain invisible, valide values are 1 (true) or 0 (false)
-- * anim: Group and index of the sprite to be used as the char's portrait when locked. If omitted, the default random select icon from the portrait will be used.
--   This uses the standard .air syntax, allowing you to specify a single sprite or define an anim, e.g.:
--   "anim": [
--       "1,0, 0,0, 10",
--       "1,1, 0,0, 10"
--   ]
--   You must add your sprites to unlockCmdSprites.sff.
--
-- EXAMPLE (in select.def):
-- kfmZ, hidden = 2, unlock = UnlockCmd("kfmZ")

--------------------------------------------------------
--- General functions
--------------------------------------------------------

function loadUnlockConfig(path)
    local file = io.open(path, "r")
    if not file then
        local defaultConfig = [[
{
  "chars": [
    {
      "name": "",
      "command": "",
      "holdstart": 0,
      "unlocked": false,
      "unlocksnd": "0, 0, 0",
      "hidden": 0,
      "anim": [
        "0,0, 0,0, -1"
      ]
    }
  ]
}
]]
        file = io.open(path, "w")
        file:write(defaultConfig)
        file:close()
    else
        file:close()
    end

    local config = json.decode(main.f_fileRead(path)) or {chars = {}}

    -- Default values
    for _, charData in ipairs(config.chars) do
        if charData.hidden == nil then
            charData.hidden = 0
        end
        if charData.holdstart == nil then
            charData.holdstart = 0
        end
        if charData.unlocked == nil then
            charData.unlocked = false
        end
        if charData.unlocksnd == nil then
            charData.unlocksnd = "0, 0, 0"
        end
    end

    return config
end

unlockConfig = loadUnlockConfig('external/mods/unlockCmdConfig.json')

function unlockCmd(name)
    for _, charData in ipairs(unlockConfig.chars) do
        if charData.name == name then
            return charData.unlocked == true
        end
    end
    return false
end

-- Table to store char anims
local charAnims = {}
-- Function to create a custom anim
function createAnim(charData)
    if not charData.anim then
        return nil
    end
    local spriteData = sffNew('external/mods/unlockCmdSprites.sff')  -- Loads the sff file
    local animString = table.concat(charData.anim, "\n")
    local anim = animNew(spriteData, animString)
    spriteData = 0
    return anim
end

-- Function to play the unlock sound
function playUnlockSound(charData)
    local centralSoundFile = sndNew('external/mods/unlockCmdSounds.snd')  -- Loads the snd file
    if charData.unlocksnd and centralSoundFile then
        local sndValues = {}
        for value in string.gmatch(charData.unlocksnd, "%d+") do
            table.insert(sndValues, tonumber(value))
        end
        if #sndValues == 3 then
            sndPlay(centralSoundFile, sndValues[1], sndValues[2], sndValues[3])
        end
    end
end

--------------------------------------------------------
--- Sprite/Anim rendering functions
--------------------------------------------------------

function DrawLockedCell()
    -- Draw cell art
    for row = 1, motif.select_info.rows do
        for col = 1, motif.select_info.columns do
            local t = start.t_grid[row][col]
            if t.skip ~= 1 then
                --draw face cell
                if t.char ~= nil and t.hidden == 0 then
                    main.f_animPosDraw(
                        start.f_getCharData(t.char_ref).cell_data,
                        motif.select_info.pos[1] + t.x + motif.select_info.portrait_offset[1],
                        motif.select_info.pos[2] + t.y + motif.select_info.portrait_offset[2],
                        (motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.portrait_facing)
                    )
                end
                if t.hidden == 2 then
                    local charAnim = charAnims[t.char]  -- Use specific char anim
                    for _, charData in ipairs(unlockConfig.chars) do
                        if charData.name == t.char and charData.hidden then
                            hidden = (charData.hidden == 1)
                            break
                        end
                    end
                    if charAnim and not hidden then
                        -- main.f_animPosDraw(
                        --     motif.select_info.cell_bg_data,
                        --     motif.select_info.pos[1] + t.x,
                        --     motif.select_info.pos[2] + t.y,
                        --     (motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_bg_facing)
                        -- )
                    -- Apply system.def scale
                        animSetScale(
                            charAnim,
                            motif.select_info.portrait_scale[1] / (main.SP_Viewport43[3] / main.SP_Localcoord[1]),
                            motif.select_info.portrait_scale[2] / (main.SP_Viewport43[3] / main.SP_Localcoord[1]),
                            false
                        )
                        --animUpdate(charAnim)
                        main.f_animPosDraw(
                            charAnim,
                            motif.select_info.pos[1] + t.x + motif.select_info.portrait_offset[1],
                            motif.select_info.pos[2] + t.y + motif.select_info.portrait_offset[2],
                            (motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_random_facing)
                        )
                    elseif not hidden then
                        main.f_animPosDraw(
                            motif.select_info.cell_random_data,
                            motif.select_info.pos[1] + t.x + motif.select_info.portrait_offset[1],
                            motif.select_info.pos[2] + t.y + motif.select_info.portrait_offset[2],
                            (motif.select_info['cell_' .. col .. '_' .. row .. '_facing'] or motif.select_info.cell_random_facing)
                        )
                    end
                end
            end
        end
    end
    --draw done cursors
    for side = 1, 2 do
        for _, v in pairs(start.p[side].t_selected) do
            if v.cursor ~= nil then
                --get cell coordinates
                local x = v.cursor[1]
                local y = v.cursor[2]
                local t = start.t_grid[y + 1][x + 1]
                --render only if cell is not hidden
                if t.hidden ~= 1 and t.hidden ~= 2 then
                    start.f_drawCursor(v.pn, x, y, '_cursor_done')
                end
            end
        end
    end

    for side = 1, 2 do
       if not start.p[side].selEnd then
            --for each player with active controls
            for k, v in ipairs(start.p[side].t_selCmd) do
                if v.selectState < 4 and start.f_selGrid(start.c[v.player].cell + 1).hidden ~= 1 and not start.c[v.player].blink then
                    start.f_drawCursor(v.player, start.c[v.player].selX, start.c[v.player].selY, '_cursor_active')
                end
            end
        end
    end
end

--------------------------------------------------------
--- Hooks and command check code
--------------------------------------------------------

function checkcommand()
    for p = 1, #main.t_players do
        for _, charData in ipairs(unlockConfig.chars) do
            if not charData.unlocked then
                main.f_commandAdd("hold_start", "/s", 1, 1)
                main.f_commandAdd(charData.name, charData.command, 150, 1)               
                local commandExecuted = commandGetState(main.t_cmd[p], charData.name)               
                if charData.holdstart == 1 then
                    commandExecuted = commandExecuted and commandGetState(main.t_cmd[p], "hold_start")
                end               
                if commandExecuted then
                    charData.unlocked = true
                    main.f_unlock(true)
                    playUnlockSound(charData)
                end
            end
            -- Load sprites/anim for locked chars
            if not charAnims[charData.name] and charData.anim then
                charAnims[charData.name] = createAnim(charData)
            end
        end
    end
    if (not start.p[1].teamEnd or not start.p[2].teamEnd or not start.p[1].selEnd or not start.p[2].selEnd) and main.stageMenu then
        DrawLockedCell()
    elseif not main.stageMenu then -- Some screenpacks use the stage select above the cells. Since we don't yet have precise control over specific layers, 
    DrawLockedCell()               -- it's better to disable the mod locked portraits during stage select to avoid issues.
    end
end

hook.add("start.f_selectScreen", "unlockchar", checkcommand)
