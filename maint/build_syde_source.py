#!/usr/bin/env python3
"""Merge upstream Syde with Alleral compat fixes into ui/syde/source.luau."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UPSTREAM = ROOT / "ui" / "syde" / "upstream.luau"
COMPAT = ROOT / "ui" / "syde" / "compat.luau"
PATCHES = ROOT / "ui" / "syde" / "patches"
OUT = ROOT / "ui" / "syde" / "source.luau"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_block(text: str, start: str, end: str) -> str:
    i = text.index(start)
    j = text.index(end, i)
    return text[i:j]


def replace_from(text: str, start: str, new_tail: str) -> str:
    i = text.index(start)
    return text[:i] + new_tail


def replace_between(text: str, start: str, end: str, new_body: str) -> str:
    i = text.index(start)
    j = text.index(end, i)
    return text[:i] + new_body + text[j:]


def convert_dropdown_block(block: str, page_expr: str, return_name: str) -> str:
    block = re.sub(
        r"local dropdown = sydeClonePageTemplate\([^)]+\)",
        f'local dropdown = sydeClonePageTemplate({page_expr}, "Dropdown")',
        block,
        count=1,
    )
    block = re.sub(
        r"local dropdown = .*?:Clone\(\)",
        f'local dropdown = sydeClonePageTemplate({page_expr}, "Dropdown")',
        block,
        count=1,
    )
    insert = (
        f'\t\t\tlocal drop = sydePrepareDropdownDrop(dropdown)\n'
        f'\t\t\tif not drop or not drop.Container then\n'
        f'\t\t\t\twarn("[Syde] Skipping dropdown: " .. tostring(data.Title))\n'
        f"\t\t\t\treturn {return_name}\n"
        f"\t\t\tend\n"
    )
    anchor = "dropdown.Name = data.Title\n"
    if anchor in block and "sydePrepareDropdownDrop(dropdown)" not in block:
        block = block.replace(anchor, anchor + insert, 1)
    block = block.replace("dropdown.dropholder.drop.selected.Text = data.PlaceHolder", "sydeSetDropSelectedText(drop, data.PlaceHolder)")
    block = block.replace("dropdown.dropholder.drop", "drop")
    return block


def adapt_modal(block: str) -> str:
    return block


def patch_ui_setup(text: str) -> str:
    old = """--@UiSetup
local ui = Library
local window = ui.main
local top = window.top
local tabs = window.tabs.tab
local pages = window.pages"""
    new = """--@UiSetup
local ui = sydeBindUi(Library)
local window = ui.main
if not window then
\tsydeWarn("[Syde] Library missing main frame")
end
local top = window and sydeFindChild(window, "top", "Top")
local tabsContainer = window and sydeFindChild(window, "tabs", "Tabs")
local tabs = tabsContainer and sydeFindChild(tabsContainer, "tab", "Tab", "tb", "Tb")
local pages = window and sydeFindChild(window, "pages", "Pages")"""
    if old not in text:
        raise RuntimeError("Syde UI setup anchor missing")
    return text.replace(old, new, 1)


def patch_dropdown_template(text: str) -> str:
    return text.replace(
        "local OptionButton = drop.Container.Option\n",
        "local OptionButton = drop.Container.Option\n\t\t\t\t\tsydeSanitizeUiClone(OptionButton)\n",
    )


def patch_dropdown_animations(text: str) -> str:
    replacements = [
        ("TweenInfo.new(1.34, Enum.EasingStyle.Quint)", "TweenInfo.new(0.38, Enum.EasingStyle.Quint)"),
        ("TweenInfo.new(1.34, Enum.EasingStyle.Exponential)", "TweenInfo.new(0.38, Enum.EasingStyle.Exponential)"),
        ("tweenservice:Create(dropdown, TweenInfo.new(1, Enum.EasingStyle.Quint)", "tweenservice:Create(dropdown, TweenInfo.new(0.32, Enum.EasingStyle.Quint)"),
        ("tweenservice:Create(drop.Container, TweenInfo.new(1, Enum.EasingStyle.Quint)", "tweenservice:Create(drop.Container, TweenInfo.new(0.32, Enum.EasingStyle.Quint)"),
        ("tweenservice:Create(drop.search, TweenInfo.new(1, Enum.EasingStyle.Exponential)", "tweenservice:Create(drop.search, TweenInfo.new(0.28, Enum.EasingStyle.Exponential)"),
        ("tweenservice:Create(drop.search.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Exponential)", "tweenservice:Create(drop.search.UIStroke, TweenInfo.new(0.28, Enum.EasingStyle.Exponential)"),
        ("tweenservice:Create(drop.search.TextBox, TweenInfo.new(1, Enum.EasingStyle.Exponential)", "tweenservice:Create(drop.search.TextBox, TweenInfo.new(0.28, Enum.EasingStyle.Exponential)"),
        ("tweenservice:Create(drop.search.ImageLabel, TweenInfo.new(1, Enum.EasingStyle.Exponential)", "tweenservice:Create(drop.search.ImageLabel, TweenInfo.new(0.28, Enum.EasingStyle.Exponential)"),
        ("tweenservice:Create(drop.search.icon, TweenInfo.new(1, Enum.EasingStyle.Exponential)", "tweenservice:Create(drop.search.icon, TweenInfo.new(0.28, Enum.EasingStyle.Exponential)"),
        ("tweenservice:Create(option, TweenInfo.new(0.7, Enum.EasingStyle.Exponential)", "tweenservice:Create(option, TweenInfo.new(0.25, Enum.EasingStyle.Exponential)"),
        ("tweenservice:Create(option, TweenInfo.new(1, Enum.EasingStyle.Exponential)", "tweenservice:Create(option, TweenInfo.new(0.3, Enum.EasingStyle.Exponential)"),
        ("tweenservice:Create(option, TweenInfo.new(0.5, Enum.EasingStyle.Quint)", "tweenservice:Create(option, TweenInfo.new(0.22, Enum.EasingStyle.Quint)"),
        ("tweenservice:Create(opt, TweenInfo.new(1, Enum.EasingStyle.Exponential)", "tweenservice:Create(opt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential)"),
        ("task.delay(1.2, function()", "task.delay(0.45, function()"),
        ("task.wait(0.6)\n\t\t\t\t\tdrop.Container.Visible = false", "task.wait(0.22)\n\t\t\t\t\tdrop.Container.Visible = false"),
        ("task.wait(0.6)\n\t\t\t\tdrop.Container.Visible = false", "task.wait(0.22)\n\t\t\t\tdrop.Container.Visible = false"),
        ("local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)", "local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)"),
    ]
    for old, new in replacements:
        text = text.replace(old, new)
    return text


def patch_ui_main_access(text: str) -> str:
    text = text.replace("Library.main", "window")
    text = text.replace("ui.main.pages", "pages")
    text = text.replace(
        "tweenservice:Create(logo.Title, TweenInfo.new(2, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()",
        "do local _logoTitle = sydeTitleLabel(logo); if _logoTitle then tweenservice:Create(_logoTitle, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play() end end",
    )
    return text


def silence_syde_logging(text: str) -> str:
    """Route Syde print/warn through silent Alleral compat stubs."""
    text = re.sub(r"\bprint\s*\(", "sydeLog(", text)
    text = re.sub(r"\bwarn\s*\(", "sydeWarn(", text)
    return text


def patch_slider_labels(text: str) -> str:
    text = text.replace(
        "Slider.Title.Text = Options.Title",
        "do local _sliderTitle = sydeSliderLabel(Slider); if _sliderTitle then _sliderTitle.Text = Options.Title end end",
    )

    def wrap_slider_create(source: str, target: str) -> str:
        prefix = f"tweenservice:Create({target},"
        play_suffix = ":Play()"
        out: list[str] = []
        i = 0
        while i < len(source):
            idx = source.find(prefix, i)
            if idx == -1:
                out.append(source[i:])
                break
            out.append(source[i:idx])
            paren_start = source.find("(", idx)
            if paren_start == -1:
                out.append(source[idx:])
                break
            depth = 0
            j = paren_start
            while j < len(source):
                ch = source[j]
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            if j >= len(source) or source[j + 1 : j + 1 + len(play_suffix)] != play_suffix:
                out.append(source[idx : idx + len(prefix)])
                i = idx + len(prefix)
                continue
            args = source[idx + len(prefix) : j]
            out.append(
                "do local _sliderTitle = sydeSliderLabel(Slider); "
                f"if _sliderTitle then tweenservice:Create(_sliderTitle,{args}):Play() end end"
            )
            i = j + 1 + len(play_suffix)
        return "".join(out)

    for target in ("Slider.Title", "sydeSliderLabel(Slider)"):
        text = wrap_slider_create(text, target)

    return text


def patch_slider_drag(text: str) -> str:
    pattern = re.compile(
        r"^(\t*)Slider\.slide\.Interact\.MouseButton1Down:Connect\(function\(\)\s*\n"
        r"\1\tdragging = true\s*\n"
        r"\1end\)\s*\n\s*\n"
        r"\1Slider\.slide\.Interact\.MouseButton1Up:Connect\(function\(\)\s*\n"
        r"\1\tdragging = false\s*\n"
        r"\1end\)",
        re.MULTILINE,
    )

    def repl(match: re.Match[str]) -> str:
        indent = match.group(1)
        inner = indent + "\t"
        return (
            f"{indent}sydeConnectSliderDrag(Slider.slide, function()\n"
            f"{inner}dragging = true\n"
            f"{indent}end, function()\n"
            f"{inner}dragging = false\n"
            f"{indent}end)"
        )

    return pattern.sub(repl, text)


def wrap_option_tween(source: str, target: str, var_name: str) -> str:
    prefix = f"tweenservice:Create({target},"
    play_suffix = ":Play()"
    out: list[str] = []
    i = 0
    while i < len(source):
        idx = source.find(prefix, i)
        if idx == -1:
            out.append(source[i:])
            break
        out.append(source[i:idx])
        paren_start = source.find("(", idx)
        if paren_start == -1:
            out.append(source[idx:])
            break
        depth = 0
        j = paren_start
        while j < len(source):
            ch = source[j]
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        if j >= len(source) or source[j + 1 : j + 1 + len(play_suffix)] != play_suffix:
            out.append(source[idx : idx + len(prefix)])
            i = idx + len(prefix)
            continue
        args = source[idx + len(prefix) : j]
        out.append(
            f"do local _optionLabel = sydeOptionLabel({var_name}); "
            f"if _optionLabel then tweenservice:Create(_optionLabel,{args}):Play() end end"
        )
        i = j + 1 + len(play_suffix)
    return "".join(out)


def patch_option_labels(text: str) -> str:
    text = re.sub(
        r"(local option = OptionButton:Clone\(\)\n)(\s+)(option\.Title\.Text = OptionText)",
        r"\1\2sydeSanitizeUiClone(option)\n\2local optionLabel = sydeOptionLabel(option)\n\2if optionLabel then\n\2\toptionLabel.Text = OptionText\n\2end",
        text,
    )
    text = re.sub(
        r'(\s+)if option:IsA\("Frame"\) and option:FindFirstChild\("Title"\) then',
        r'\1local optionLabel = sydeOptionLabel(option)\n\1if option:IsA("Frame") and optionLabel then',
        text,
    )
    text = text.replace(
        "local optionText = option.Title.Text:lower()",
        "local optionText = optionLabel.Text:lower()",
    )
    text = text.replace(
        "SelectedOptions[option.Title.Text]",
        "SelectedOptions[optionLabel.Text]",
    )
    for target, var_name in (("option.Title", "option"), ("opt.Title", "opt")):
        text = wrap_option_tween(text, target, var_name)
    text = text.replace(
        "do local _optionLabel = sydeOptionLabel(option); if _optionLabel then tweenservice:Create(_optionLabel,",
        "if optionLabel then tweenservice:Create(optionLabel,",
    )
    text = re.sub(
        r"(if optionLabel then tweenservice:Create\(optionLabel,[^\n]+\):Play\(\)) end end",
        r"\1 end",
        text,
    )
    return text


def patch_option_clicks(text: str) -> str:
    return text.replace(
        "option.Interact.MouseButton1Click:Connect(function()",
        "sydeConnectClick(option, function()",
    )


def patch_normalized_labels(text: str) -> str:
    text = text.replace(
        "LOADER.loader.profile.Title.TextTransparency = 1",
        "do local _profileTitle = sydeLoaderProfileLabel(LOADER); if _profileTitle then _profileTitle.TextTransparency = 1 end end",
    )
    text = text.replace(
        "LOADER.loader.profile.Title.Text = Config.Name",
        "do local _profileTitle = sydeLoaderProfileLabel(LOADER); if _profileTitle then _profileTitle.Text = Config.Name end end",
    )
    text = text.replace(
        "LOADER.loader.profile.Title.Text = LoaderConfig.Name",
        "do local _profileTitle = sydeLoaderProfileLabel(LOADER); if _profileTitle then _profileTitle.Text = LoaderConfig.Name end end",
    )
    text = text.replace(
        'if clone:FindFirstChild("Title") then\n\t\t\t\tclone.Title.Text = value\n\t\t\tend',
        "do local _cloneTitle = sydeTitleLabel(clone); if _cloneTitle then _cloneTitle.Text = value end end",
    )
    notif_anchor = "\t\tlocal Notification = Library.Notification.Default:Clone()\n\t\tNotification.Visible = true"
    notif_insert = notif_anchor + "\n\t\tlocal notificationTitle = sydeTitleLabel(Notification)"
    if notif_anchor in text and "local notificationTitle = sydeTitleLabel(Notification)" not in text:
        text = text.replace(notif_anchor, notif_insert, 1)
    text = text.replace(
        "Notification.Title.Text = NotifData.Title",
        "if notificationTitle then notificationTitle.Text = NotifData.Title end",
    )
    text = text.replace(
        "syde:WiggleText(Notification.Title)",
        "if notificationTitle then syde:WiggleText(notificationTitle) end",
    )
    text = text.replace(
        "tweenservice:Create(Notification.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 40,0, 10)}):Play()",
        "if notificationTitle then tweenservice:Create(notificationTitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 40,0, 10)}):Play() end",
    )
    text = text.replace(
        '\t\t\tlocal Section =  sydeClonePageTemplate(pages.page, "Section")\n\t\t\tSection.Visible = true\n\t\t\tSection.Title.Text = Title',
        '\t\t\tlocal Section =  sydeClonePageTemplate(pages.page, "Section")\n\t\t\tSection.Visible = true\n\t\t\tlocal sectionTitle = sydeTitleLabel(Section)\n\t\t\tif sectionTitle then sectionTitle.Text = Title end',
    )
    text = text.replace(
        "Section.Title.Position = UDim2.new(0, 0,0, 0)",
        "if sectionTitle then sectionTitle.Position = UDim2.new(0, 0,0, 0) end",
    )
    text = text.replace(
        "Section.Title.Position = UDim2.new(0, 25,0, 0)",
        "if sectionTitle then sectionTitle.Position = UDim2.new(0, 25,0, 0) end",
    )
    text = text.replace(
        '\t\t\tlocal EnchancedView = sydeClonePageTemplate(pages.page, "3DView")\n\t\t\tEnchancedView.Visible = true\n\t\t\tEnchancedView.Parent = Page\n\t\t\tEnchancedView.Title.Text = Viewdata.Title',
        '\t\t\tlocal EnchancedView = sydeClonePageTemplate(pages.page, "3DView")\n\t\t\tEnchancedView.Visible = true\n\t\t\tEnchancedView.Parent = Page\n\t\t\tlocal viewTitle = sydeTitleLabel(EnchancedView)\n\t\t\tif viewTitle then viewTitle.Text = Viewdata.Title end',
    )
    text = text.replace(
        "drop.Selected.Text = OptionText",
        "sydeSetDropSelectedText(drop, OptionText)",
    )
    return text


def patch_runtime_safety(text: str) -> str:
    text = text.replace("setclipboard(", "sydeSetClipboard(")
    text = text.replace(
        "local screenSize =      workspace.CurrentCamera.ViewportSize",
        "local screenSize =      sydeGetCurrentCamera().ViewportSize",
    )
    text = text.replace(
        "local camera =          workspace.CurrentCamera",
        "local camera =          sydeGetCurrentCamera()",
    )
    text = text.replace(
        "local camera = workspace.CurrentCamera",
        "local camera = sydeGetCurrentCamera()",
    )
    text = text.replace("RunService.RenderStepped:wait()", "RunService.RenderStepped:Wait()")
    text = text.replace(
        "if dragging and input.UserInputType == Enum.UserInputType.MouseMovement  or input.UserInputType == Enum.UserInputType.Touch  then",
        "if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then",
    )
    text = text.replace(
        "table.remove(notifications, table.find(notifications, Notification))",
        "local notificationIndex = table.find(notifications, Notification)\n\t\t\t\tif notificationIndex then table.remove(notifications, notificationIndex) end",
    )
    text = text.replace(
        "repeat task.wait() until graph.AbsoluteSize.X > 0",
        "local graphDeadline = os.clock() + 5\n\t\trepeat task.wait() until graph.AbsoluteSize.X > 0 or not graph.Parent or os.clock() >= graphDeadline\n\t\tif not graph.Parent or graph.AbsoluteSize.X <= 0 then\n\t\t\twarn(\"[Syde] Latency graph did not become ready\")\n\t\telse",
    )
    text = text.replace(
        "\t\tlocal bh = window.pages.home.general.Quick.QuickSettings.QuickButtons.holder",
        "\t\tend\n\n\t\tlocal bh = window.pages.home.general.Quick.QuickSettings.QuickButtons.holder",
        1,
    )
    text = text.replace(
        "\t\t\twhile true do\n\n\t\t\t\tlocal ping = getPing()",
        "\t\t\twhile Library and Library.Parent and graph.Parent do\n\n\t\t\t\tlocal ping = getPing()",
        1,
    )
    text = text.replace(
        "\t\t\tif not syde.ConfigEnabled then return end\n\n\t\t\tlocal data = {",
        "\t\t\tif not syde.ConfigEnabled or type(writefile) ~= \"function\" then return end\n\n\t\t\tlocal data = {",
        1,
    )
    text = text.replace(
        "\t\t\tif not syde.ConfigEnabled then return nil end\n\t\t\tif not isfile(FILE) then return nil end",
        "\t\t\tif not syde.ConfigEnabled or type(isfile) ~= \"function\" or type(readfile) ~= \"function\" then return nil end\n\t\t\tif not isfile(FILE) then return nil end",
        1,
    )
    text = text.replace(
        "TeleportService:Teleport(placeId)",
        "TeleportService:Teleport(lastGame.PlaceId)",
        1,
    )
    text = text.replace(
        "\t\t\t\t\t\tOptions:Set(newValue)\n\t\t\t\t\t\tSaveConfig()",
        "\t\t\t\t\t\tOptions.StarterValue = newValue\n\t\t\t\t\t\tSaveConfig()",
        1,
    )
    text = text.replace(
        'string.format("<font size=\'14\'>%d</font><font color=\'#434343\'>/%d</font>", tostring(NewVal), Options.Range[2])',
        'string.format("<font size=\'14\'>%d</font><font color=\'#434343\'>/%d</font>", NewVal, Options.Range[2])',
    )
    text = text.replace(
        "if isfolder and not isfolder(syde.ConfigFolder) then\n\t\tmakefolder(syde.ConfigFolder)\n\tend",
        "if type(isfolder) ~= \"function\" or type(makefolder) ~= \"function\" or type(writefile) ~= \"function\" then return end\n\tif not isfolder(syde.ConfigFolder) then\n\t\tmakefolder(syde.ConfigFolder)\n\tend",
        1,
    )
    text = text.replace(
        "\t\t\t\tif success then\n\t\t\t\t\tsyde:Toast({\n\t\t\t\t\t\tContent = 'Loaded Save File';",
        "\t\t\t\tif success and loaded then\n\t\t\t\t\tsyde:Toast({\n\t\t\t\t\t\tContent = 'Loaded Save File';",
        1,
    )
    text = text.replace(
        "\t\t\t\telseif not success then\n\t\t\t\t\tsydeWarn(\"[SYDE] Configurations Error \" .. tostring(result))",
        "\t\t\t\telseif not success then\n\t\t\t\t\tsydeWarn(\"[SYDE] Configurations Error \" .. tostring(result))\n\t\t\t\telse\n\t\t\t\t\tsydeWarn(\"[SYDE] No valid save file was loaded\")",
        1,
    )
    return text


def main() -> None:
    upstream = read(UPSTREAM)
    compat = read(COMPAT)
    modal_block = adapt_modal(read(PATCHES / "modal.luau"))

    loader_match = re.search(
        r"(local Loader\s*=.*?110221114597158.*?\[1\]\s*\n)",
        upstream,
        re.DOTALL,
    )
    if not loader_match:
        raise RuntimeError("Could not find Loader assignment in upstream Syde")
    insert_at = loader_match.end()
    body = upstream[:insert_at] + "\n" + compat + "\n" + upstream[insert_at:]

    body = re.sub(
        r"window\.settings\.pages\.page\.(\w+):Clone\(\)",
        r'sydeClonePageTemplate(window.settings.pages.page, "\1")',
        body,
    )
    body = re.sub(
        r'window\.settings\.pages\.page\["3DView"\]:Clone\(\)',
        r'sydeClonePageTemplate(window.settings.pages.page, "3DView")',
        body,
    )
    body = re.sub(
        r"pages\.page\.(\w+):Clone\(\)",
        r'sydeClonePageTemplate(pages.page, "\1")',
        body,
    )
    body = re.sub(
        r'pages\.page\["3DView"\]:Clone\(\)',
        r'sydeClonePageTemplate(pages.page, "3DView")',
        body,
    )

    body = body.replace(
        "function tbdata:InitTab(tab)\n",
        "function tbdata:InitTab(tab)\n\t\tif type(tab) == \"string\" then\n\t\t\ttab = { Title = tab }\n\t\tend\n",
        1,
    )

    keybind_patch = "\n\tif library.Keybind then\n\t\tuitoggle = library.Keybind\n\tend\n"
    anchor = "\tData.Home.profileImage = Data.Home.profileImage or Data.profileImage"
    if anchor in body and keybind_patch.strip() not in body:
        body = body.replace(anchor, anchor + keybind_patch, 1)

    body = replace_between(body, "function syde:Modal(Modal)", "--@@Toast", modal_block)

    settings_dropdown = convert_dropdown_block(
        extract_block(upstream, "function telement:Dropdown(Dropdown)", "\n\t\t\tfunction telement:Slider"),
        "window.settings.pages.page",
        "telement",
    )
    body = replace_between(
        body,
        "function telement:Dropdown(Dropdown)",
        "\n\t\t\tfunction telement:Slider",
        settings_dropdown,
    )

    page_dropdown = convert_dropdown_block(
        extract_block(upstream, "function initelement:Dropdown(Dropdown)", "\n\t\t--@@Colorpicker"),
        "pages.page",
        "initelement",
    )
    body = replace_between(
        body,
        "function initelement:Dropdown(Dropdown)",
        "\n\t\t--@@Colorpicker",
        page_dropdown,
    )

    footer_start = "\t\treturn initelement\n\n\n\tend\n\treturn tbdata"
    end_patch = """
\t\tfunction initelement:Select()
\t\t\tSwitchToTab(tdata.Title)
\t\tend

\t\treturn initelement


\tend

\tfunction tbdata:Toggle()
\t\tToggleUI()
\tend

\tfunction tbdata:GetState()
\t\treturn not uiclosed
\tend

\tfunction tbdata:SetState(state)
\t\tlocal want = state == true
\t\tif want and uiclosed then
\t\t\tToggleUI()
\t\telseif not want and not uiclosed then
\t\t\tToggleUI()
\t\tend
\tend

\treturn tbdata


end

syde.__AlleralPatch = ALLERAL_SYDE_PATCH

return syde
"""
    if footer_start not in body:
        raise RuntimeError("Syde Init footer anchor missing — upstream layout changed")
    body = replace_from(body, footer_start, end_patch)

    body = silence_syde_logging(body)
    body = patch_ui_setup(body)
    body = patch_slider_labels(body)
    body = patch_slider_drag(body)
    body = patch_option_labels(body)
    body = patch_option_clicks(body)
    body = patch_normalized_labels(body)
    body = patch_dropdown_template(body)
    body = patch_dropdown_animations(body)
    body = patch_ui_main_access(body)
    body = patch_runtime_safety(body)
    body = "\n".join(line.rstrip() for line in body.splitlines()) + "\n"

    if "--check" in sys.argv:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != body:
            raise SystemExit(f"{OUT} is stale; run python maint/build_syde_source.py")
        print(f"OK: {OUT} is up to date")
        return

    OUT.write_text(body, encoding="utf-8")
    print(f"Wrote {OUT} ({len(body)} bytes, {body.count(chr(10)) + 1} lines)")


if __name__ == "__main__":
    main()
