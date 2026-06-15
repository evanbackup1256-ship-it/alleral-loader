function telement:Dropdown(Dropdown)
    local data = {
        Title = Dropdown.Title or "Temp Dropdown";
        Options = Dropdown.Options or {};
        StarterOption = Dropdown.StarterOption;
        PlaceHolder = Dropdown.PlaceHolder or "Select Option...";
        Multi = Dropdown.Multi or false;
        CallBack = Dropdown.CallBack;
    }

    local dropdown = sydeClonePageTemplate(window.settings.pages.page, "Dropdown")
    sydeSanitizeUiClone(dropdown)
    dropdown.Visible = true
    dropdown.Parent = Page
    dropdown.title.Text = data.Title
    dropdown.Name = data.Title

    local drop = sydePrepareDropdownDrop(dropdown)
    if not drop or not drop.Container then
        warn("[Syde] Skipping dropdown (no valid drop frame): " .. tostring(data.Title))
        return telement
    end

    drop.Container.Option.Visible = false
    drop.Container.Visible = false

    tweenservice:Create(drop.Container, TweenInfo.new(1, Enum.EasingStyle.Quint), { 
        Size = UDim2.new(0.33, -20, 0.576, -75) 
    }):Play()

    sydeSetDropSelectedText(drop, data.PlaceHolder)

    local DropOpen = false
    local DeBounce = false
    local OptionButton = drop.Container.Option
    local SelectedOptions = {}
    local SelectedOrder = {}

    local function UpdateCustomLayout()
        local yOffset = 0
        for _, option in ipairs(drop.Container:GetChildren()) do
            if option:IsA("Frame") and option.Visible then
                tweenservice:Create(option, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
                    Position = UDim2.new(0, 0, 0, yOffset)
                }):Play()
                yOffset = yOffset + option.Size.Y.Offset + 7
            end
        end
    end

    local function OpenDrop()
        DropOpen = true
        drop.Container.Visible = true
        if drop.search then drop.search.Visible = true end

        tweenservice:Create(dropdown, TweenInfo.new(1.34, Enum.EasingStyle.Quint), { 
            Size = UDim2.new(1, -35, 0, 300) 
        }):Play()

        if drop.UICorner then
            tweenservice:Create(drop.UICorner, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { 
                CornerRadius = UDim.new(0, 20) 
            }):Play()
        end

        tweenservice:Create(drop.Container, TweenInfo.new(1, Enum.EasingStyle.Quint), { 
            Size = UDim2.new(1, -20, 1, -75) 
        }):Play()

        if drop.v0 then
            tweenservice:Create(drop.v0, TweenInfo.new(1.34, Enum.EasingStyle.Exponential), { 
                BackgroundTransparency = 0 
            }):Play()
        end
        if drop.down then
            tweenservice:Create(drop.down, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { 
                Rotation = 180 
            }):Play()
        end

        if drop.search then
            tweenservice:Create(drop.search, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                BackgroundTransparency = 0.65 
            }):Play()
            if drop.search.UIStroke then
                tweenservice:Create(drop.search.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                    Transparency = 0.4 
                }):Play()
            end
            if drop.search.TextBox then
                tweenservice:Create(drop.search.TextBox, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                    TextTransparency = 0 
                }):Play()
            end
            if drop.search.ImageLabel then
                tweenservice:Create(drop.search.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                    ImageTransparency = 0.9 
                }):Play()
            end
            if drop.search.icon then
                tweenservice:Create(drop.search.icon, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                    ImageTransparency = 0.85 
                }):Play()
            end
        end
    end

    local function CloseDrop()
        DropOpen = false
        tweenservice:Create(dropdown, TweenInfo.new(1, Enum.EasingStyle.Quint), { 
            Size = UDim2.new(1, -35, 0, 95) 
        }):Play()

        if drop.UICorner then
            tweenservice:Create(drop.UICorner, TweenInfo.new(1, Enum.EasingStyle.Quint), { 
                CornerRadius = UDim.new(1, 0) 
            }):Play()
        end

        tweenservice:Create(drop.Container, TweenInfo.new(1, Enum.EasingStyle.Quint), { 
            Size = UDim2.new(0.33, -20, 0.576, -75) 
        }):Play()

        if drop.v0 then
            tweenservice:Create(drop.v0, TweenInfo.new(1.34, Enum.EasingStyle.Exponential), { 
                BackgroundTransparency = 1 
            }):Play()
        end
        if drop.down then
            tweenservice:Create(drop.down, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { 
                Rotation = 0 
            }):Play()
        end

        if drop.search then
            tweenservice:Create(drop.search, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                BackgroundTransparency = 1 
            }):Play()
            if drop.search.UIStroke then
                tweenservice:Create(drop.search.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                    Transparency = 1 
                }):Play()
            end
            if drop.search.TextBox then
                tweenservice:Create(drop.search.TextBox, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                    TextTransparency = 1 
                }):Play()
            end
            if drop.search.ImageLabel then
                tweenservice:Create(drop.search.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                    ImageTransparency = 1 
                }):Play()
            end
            if drop.search.icon then
                tweenservice:Create(drop.search.icon, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                    ImageTransparency = 1 
                }):Play()
            end
        end

        task.wait(0.6)
        drop.Container.Visible = false
        if drop.search then drop.search.Visible = false end
    end

    sydeConnectDropdownToggle(drop, function()
        if DeBounce then return end
        DeBounce = true

        if DropOpen then
            CloseDrop()
        else
            OpenDrop()
        end

        task.delay(0.35, function()
            DeBounce = false
        end)
    end)

    local function AddToSelected(option)
        if not SelectedOptions[option] then
            SelectedOptions[option] = true

            local originalIndex
            for i, opt in ipairs(data.Options) do
                if opt == option then
                    originalIndex = i
                    break
                end
            end

            local insertIndex = 1
            for i, selected in ipairs(SelectedOrder) do
                local selectedIndex = table.find(data.Options, selected)
                if selectedIndex and selectedIndex < originalIndex then
                    insertIndex = i + 1
                else
                    break
                end
            end

            table.insert(SelectedOrder, insertIndex, option)
        end
    end

    local function RemoveFromSelected(option)
        if SelectedOptions[option] then
            SelectedOptions[option] = nil
            for i = #SelectedOrder, 1, -1 do
                if SelectedOrder[i] == option then
                    table.remove(SelectedOrder, i)
                    break
                end
            end
        end

        local selectedContainer = drop.selectContainer and drop.selectContainer.ScrollingFrame
        if selectedContainer then
            for _, child in ipairs(selectedContainer:GetChildren()) do
                if child:IsA("Frame") and child.Name == option then
                    child:Destroy()
                    break
                end
            end
        end
    end

    local function UpdateSelectedText()
        local selectedContainer = drop.selectContainer and drop.selectContainer.ScrollingFrame
        local hasSelectedContainer = selectedContainer ~= nil

        if hasSelectedContainer then
            selectedContainer.Visible = data.Multi
        end

        if data.Multi then
            if drop.selected then drop.selected.Visible = false end

            if #SelectedOrder == 0 then
                if drop.selected then
                    drop.selected.Visible = true
                    drop.selected.Text = data.PlaceHolder
                end
                if hasSelectedContainer then selectedContainer.Visible = false end
                return
            end

            -- Create chips
            for _, optionText in ipairs(SelectedOrder) do
                if hasSelectedContainer and not selectedContainer:FindFirstChild(optionText) then
                    local template = selectedContainer:FindFirstChild("result")
                    if template then
                        local optionGroup = template:Clone()
                        optionGroup.Visible = true
                        optionGroup.Name = optionText
                        if optionGroup:FindFirstChild("TextLabel") then
                            optionGroup.TextLabel.Text = optionText
                        end

                        -- Remove button
                        local removeBtn = optionGroup:FindFirstChild("X")
                        if removeBtn then
                            removeBtn.MouseButton1Click:Connect(function()
                                RemoveFromSelected(optionText)
                                UpdateSelectedText()

                                for _, opt in ipairs(drop.Container:GetChildren()) do
                                    if opt:IsA("Frame") and opt.Name == optionText then
                                        tweenservice:Create(opt, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                                            BackgroundTransparency = 0 
                                        }):Play()
                                        tweenservice:Create(opt, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                                            BackgroundColor3 = Color3.fromRGB(33, 33, 33) 
                                        }):Play()

                                        local lbl = sydeOptionLabel(opt) or sydeTitleLabel(opt)
                                        if lbl then
                                            tweenservice:Create(lbl, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                                                TextTransparency = 0 
                                            }):Play()
                                        end

                                        if opt:FindFirstChild("UIStroke") then
                                            tweenservice:Create(opt.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                                                Transparency = 0.5 
                                            }):Play()
                                        end
                                        if opt:FindFirstChild("ImageLabel") then
                                            tweenservice:Create(opt.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { 
                                                ImageTransparency = 0.9 
                                            }):Play()
                                        end
                                    end
                                end

                                if data.CallBack then data.CallBack(SelectedOrder) end
                            end)
                        end

                        optionGroup.Parent = selectedContainer

                        task.defer(function()
                            if optionGroup:FindFirstChild("TextLabel") then
                                local textWidth = optionGroup.TextLabel.TextBounds.X
                                optionGroup.TextLabel.Size = UDim2.new(0, textWidth, 1, 0)
                                tweenservice:Create(optionGroup, TweenInfo.new(0.67, Enum.EasingStyle.Exponential), { 
                                    Size = UDim2.new(0, textWidth + 40, 0, 20) 
                                }):Play()
                            end
                        end)
                    end
                end
            end
        else
            -- Single select mode
            if drop.selected then
                drop.selected.Visible = true
                if #SelectedOrder > 0 then
                    drop.selected.Text = SelectedOrder[1]
                else
                    drop.selected.Text = data.PlaceHolder
                end
            end
            if hasSelectedContainer then
                selectedContainer.Visible = false
            end
        end
    end

    -- SEARCH
    if drop.search and drop.search.TextBox then
        drop.search.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
            local searchText = drop.search.TextBox.Text:lower()

            for _, option in ipairs(drop.Container:GetChildren()) do
                if option:IsA("Frame") then
                    local optionLabel = sydeTitleLabel(option) or sydeOptionLabel(option)
                    if optionLabel then
                        local optionText = optionLabel.Text:lower()
                        local isTemplate = option.Name == "Option"
                        local shouldShow = not isTemplate and 
                            (searchText == "" or optionText:find(searchText, 1, true) or SelectedOptions[optionLabel.Text])

                        if shouldShow then
                            option.Visible = true
                            if SelectedOptions[optionLabel.Text] then
                                tweenservice:Create(option, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
                                tweenservice:Create(option, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { BackgroundColor3 = Color3.fromRGB(39, 39, 39) }):Play()
                                tweenservice:Create(optionLabel, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
                                if option:FindFirstChild("UIStroke") then
                                    tweenservice:Create(option.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { Transparency = 1 }):Play()
                                end
                                if option:FindFirstChild("ImageLabel") then
                                    tweenservice:Create(option.ImageLabel, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { ImageTransparency = 0 }):Play()
                                end
                            else
                                tweenservice:Create(option, TweenInfo.new(1, Enum.EasingStyle.Exponential), { BackgroundTransparency = 0 }):Play()
                                tweenservice:Create(option, TweenInfo.new(1, Enum.EasingStyle.Exponential), { BackgroundColor3 = Color3.fromRGB(33, 33, 33) }):Play()
                                tweenservice:Create(optionLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { TextTransparency = 0 }):Play()
                                if option:FindFirstChild("UIStroke") then
                                    tweenservice:Create(option.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential), { Transparency = 0.5 }):Play()
                                end
                                if option:FindFirstChild("ImageLabel") then
                                    tweenservice:Create(option.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential), { ImageTransparency = 0.9 }):Play()
                                end
                            end
                        else
                            tweenservice:Create(option, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { BackgroundTransparency = 1 }):Play()
                            tweenservice:Create(option, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { BackgroundColor3 = Color3.fromRGB(33, 33, 33) }):Play()
                            tweenservice:Create(optionLabel, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { TextTransparency = 1 }):Play()
                            if option:FindFirstChild("UIStroke") then
                                tweenservice:Create(option.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { Transparency = 1 }):Play()
                            end
                            if option:FindFirstChild("ImageLabel") then
                                tweenservice:Create(option.ImageLabel, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), { ImageTransparency = 1 }):Play()
                            end
                            option.Visible = false
                        end
                    end
                end
            end

            UpdateCustomLayout()
        end)
    end

    local function SetDropdownOptions()
        local starterSet = false

        for _, OptionText in ipairs(data.Options) do
            local option = OptionButton:Clone()
            sydeSanitizeUiClone(option)

            local optionLabel = sydeTitleLabel(option) or sydeOptionLabel(option)
            if optionLabel then
                optionLabel.Text = OptionText
            end

            option.Parent = drop.Container
            option.Visible = true
            option.Name = OptionText

            if OptionText == data.StarterOption and not starterSet then
                starterSet = true
                if drop.selected then drop.selected.Text = OptionText end
                SelectedOptions = { [OptionText] = true }
                SelectedOrder = { OptionText }

                tweenservice:Create(option, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(39, 39, 39) }):Play()
                if option:FindFirstChild("ImageLabel") then
                    tweenservice:Create(option.ImageLabel, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()
                end
            end

            sydeConnectClick(option, function()
                if data.Multi then
                    if SelectedOptions[OptionText] then
                        RemoveFromSelected(OptionText)
                        tweenservice:Create(option, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(33, 33, 33) }):Play()
                        if option:FindFirstChild("ImageLabel") then
                            tweenservice:Create(option.ImageLabel, TweenInfo.new(0.3), { ImageTransparency = 0.9 }):Play()
                        end
                    else
                        AddToSelected(OptionText)
                        tweenservice:Create(option, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(39, 39, 39) }):Play()
                        if option:FindFirstChild("ImageLabel") then
                            tweenservice:Create(option.ImageLabel, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()
                        end
                    end

                    if data.CallBack then data.CallBack(SelectedOrder) end
                else
                    if drop.selected then drop.selected.Text = OptionText end
                    SelectedOptions = { [OptionText] = true }
                    SelectedOrder = { OptionText }

                    for _, opt in ipairs(drop.Container:GetChildren()) do
                        if opt:IsA("Frame") then
                            tweenservice:Create(opt, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(33, 33, 33) }):Play()
                            if opt:FindFirstChild("ImageLabel") then
                                tweenservice:Create(opt.ImageLabel, TweenInfo.new(0.3), { ImageTransparency = 0.9 }):Play()
                            end
                        end
                    end

                    tweenservice:Create(option, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(39, 39, 39) }):Play()
                    if option:FindFirstChild("ImageLabel") then
                        tweenservice:Create(option.ImageLabel, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()
                    end

                    if data.CallBack then data.CallBack(OptionText) end
                    CloseDrop()
                end

                UpdateSelectedText()
            end)
        end

        if not starterSet and drop.selected then
            drop.selected.Text = data.PlaceHolder
        end

        UpdateCustomLayout()
    end

    SetDropdownOptions()
    return telement
end