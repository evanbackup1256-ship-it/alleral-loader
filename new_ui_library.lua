local source =
	game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Starlight-Interface-Suite/master/Source.lua")

source = source:gsub(
	"function Tab:Show%(%)[\r\n]+%s*if Library%.ActiveTab then",
	"function Tab:Show()\n\t\t\tif Library.ActiveTab == Tab then\n\t\t\t\treturn\n\t\t\tend\n\t\t\tif Library.ActiveTab then"
)

local inputStart = source:find("function Groupbox:CreateInput", 1, true)
local labelStart = inputStart and source:find("function Groupbox:CreateLabel", inputStart, true)

if inputStart and labelStart then
	local before = source:sub(1, inputStart - 1)
	local block = source:sub(inputStart, labelStart - 1)
	local after = source:sub(labelStart)

	block = block:gsub(
		"(Element%.Instance = GroupboxTemplateInstance%.Input_TEMPLATE:Clone%(%)[\r\n]+%s*Element%.Instance%.Visible = true)",
		"%1\n\t\t\t\t\t\tElement.Instance.Parent = Groupbox.ParentingItem",
		1
	)
	block = block:gsub(
		"\n%s*Element%.Instance%.Parent = Groupbox%.ParentingItem\n\n%s*(Starlight%.Window%.TabSections%[Name%]%.Tabs%[TabIndex%]%.Groupboxes%[GroupIndex%]%.Elements%[Index%] = Element)",
		"\n\n\t\t\t\t\t%1",
		1
	)

	source = before .. block .. after
end

return loadstring(source)()
