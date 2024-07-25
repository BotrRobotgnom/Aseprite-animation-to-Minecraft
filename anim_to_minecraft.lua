-- Author: BotrRobotgnom
-- GitHub: https://github.com/BotrRobotgnom/Aseprite-animation-to-Minecraft

if app.activeSprite ~= nil then
    local dlg = Dialog{title = "AAtoM v0.3"}

    -- Add elements to the dialog window
    dlg:label{ id="label", text="Select save type:" }
    dlg:combobox{ id="saveType", option="simple", options={ "simple" } }
    dlg:newrow()

    dlg:label{ id="fpsLabel", text="Frames per second:" }
    dlg:entry{ id="fpsEntry", text=tostring(#app.activeSprite.frames) }
    dlg:newrow()

    -- Function called when the "Save" button is clicked
    function onSaveButtonClick()
        local data = dlg.data
        -- Access the current sprite
        local spr = app.activeSprite

        -- Get the width and height of the first frame
        local width = spr.width
        local height = spr.height

        filename = spr.filename:match("^(.+)%..+$")

        if filename == nil then
            local err_dlg = Dialog { title = "Error exporting mc animation" }
            err_dlg:label { id = "errLabel", text = "Failed to export mc animation to file because it has not been saved yet" }
            err_dlg:show()
            return
        end

        -- Create a new sprite with the desired width and height
        local newSpr = Sprite(width, height * #spr.frames, spr.colorMode, spr.pixelRatio)
        local newLayer = newSpr.layers[1]
        local newFrame = newSpr.frames[1]
        local newCel = newSpr:newCel(newLayer, newFrame)

        -- Iterate over each animation frame
        for i, frame in ipairs(spr.frames) do
            -- Get the image of the current frame
            local cel = spr.layers[1]:cel(frame.frameNumber)
            if cel ~= nil then
                local image = cel.image

                -- Get the position offset of the original frame
                local xOffset = cel.position.x
                local yOffset = cel.position.y

                -- Calculate the position to insert the frame in the new sprite
                local position = Point(xOffset, height * (i - 1) + yOffset)

                -- Insert the frame image into the new sprite
                newCel.image:drawImage(image, position)
            end
        end

        newSpr:saveAs(filename..".png")
        newSpr:close()

        framespeed = tonumber(data.fpsEntry)

        -- Create animation data in JSON format
        local animationData = {
            animation = {
                frametime = framespeed, -- Calculate the duration of one frame
                frames = {}
            }
        }

        -- Create JSON string manually
        local jsonData = '{\n  "animation": {\n'
        jsonData = jsonData .. '    "frametime": ' .. animationData.animation.frametime .. ',\n'
        jsonData = jsonData .. '    "frames": [\n'

        -- Check the selected save type
        if data.saveType == "simple" then
            -- Add each animation frame to the table
            for i, frame in ipairs(spr.frames) do
                local frameData = {
                    index = i - 1, -- Frame index (starting from 0)
                }
                table.insert(animationData.animation.frames, frameData)
            end

            for i, frameData in ipairs(animationData.animation.frames) do
                jsonData = jsonData .. '      ' .. frameData.index
                if i < #animationData.animation.frames then
                    jsonData = jsonData .. ','
                end
                jsonData = jsonData .. '\n'
            end
        end

        jsonData = jsonData .. '    ]\n}\n}\n'

        -- Create the mcmeta file and write the data to it
        local mcmetaFile = io.open(filename .. ".png.mcmeta", "w")
        mcmetaFile:write(jsonData)
        mcmetaFile:close()

        -- Close the dialog window
        dlg:close()
    end

    -- Attach the function to the "Save" button click event
    dlg:button{ text="Save", onclick=onSaveButtonClick }

    -- Display the dialog window
    dlg:show()
else 
    app.alert {
        title = "Error",
        text = "No active sprite found.",
        buttons = { "OK" }
    }  
end
