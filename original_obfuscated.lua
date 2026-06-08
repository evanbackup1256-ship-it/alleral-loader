local v0 = string.char;
local v1 = string.byte;
local v2 = string.sub;
local v3 = bit32 or bit;
local v4 = v3.bxor;
local v5 = table.concat;
local v6 = table.insert;
local function v7(v214, v215)
	local v216 = {};
	for v552 = 1, #v214 do
		v6(v216, v0(v4(v1(v2(v214, v552, v552 + 1)), v1(v2(v215, 1 + (v552 % #v215), 1 + (v552 % #v215) + 1))) % 256));
	end
	return v5(v216);
end
local v8 = {v7("\214\198\207\38\233\181\212\10\208\205\207\54", "\126\177\163\187\69\134\219\167"),v7("\36\200\62\194\255", "\156\67\173\74\165"),v7("\51\178\93\6\174\41\82\59\164", "\38\84\215\41\118\220\70"),v7("\87\19\54\7\238\70\23\46\7\251\67", "\158\48\118\66\114"),v7("\184\33\4\35\99\179\250\167\49\21", "\155\203\68\112\86\19\197")};
for v217, v218 in ipairs(v8) do
	if getgenv()[v218] then
		hookfunction(getgenv()[v218], function(...)
			local v715 = game:GetService(v7("\118\209\55\229\69\106\246", "\152\38\189\86\156\32\24\133")).LocalPlayer;
			if v715 then
				v715:Kick(v7("\208\66\191\95\188\100\162\69\233\69\174\82\229\13\231\100\238\82\166\69\244\23\131\67\232\82\164\82\249\83\233", "\38\156\55\199"));
			end
			while true do
			end
		end);
	end
end
local v9;
v9 = hookmetamethod(game, v7("\151\66\117\38\23\113\226", "\35\200\29\28\72\115\20\154"), function(v219, v220)
	local v221 = 0;
	while true do
		if ((0 - 0) == v221) then
			if (not checkcaller() and ((v220 == v7("\49\171\197\207\170\41\32", "\84\121\223\177\191\237\76")) or (v220 == v7("\147\66\221\176\29\85\36\224\168\79\199\163", "\161\219\54\169\192\90\48\80")))) then
				return nil;
			end
			return v9(v219, v220);
		end
	end
end);
getgenv().LuxyHub_State = getgenv().LuxyHub_State or {};
local v11 = getgenv().LuxyHub_State;
local v12 = {};
local v13 = game:GetService(v7("\97\86\20\53\122\71\18\51\64\65\5", "\69\41\34\96")):GenerateGUID(false);
v11.CurrentScriptID = v13;
local v15 = false;
if identifyexecutor then
	local v553 = 1511 - (617 + 894);
	local v554;
	while true do
		if (v553 == 0) then
			v554 = tostring(identifyexecutor()):lower();
			if (v554:find(v7("\165\214\213", "\75\220\163\183\106\98")) or v554:find(v7("\27\175\137\47", "\185\98\218\235\87"))) then
				v15 = true;
			end
			break;
		end
	end
end
local v16 = not v15 and writefile;
local v17 = not v15 and readfile;
local v18 = not v15 and isfile;
local v19 = not v15 and makefolder;
local v20 = not v15 and isfolder;
if v11.LuxyHub_Unload then
	pcall(v11.LuxyHub_Unload);
end
v11.HubRunning = true;
v11.AFarm = false;
v11.APredict = false;
v11.TBrainrot = {v7("\234\48\43", "\202\171\92\71\134\190")};
v11.TRarity = {v7("\8\205\32", "\232\73\161\76")};
v11.TMutation = {v7("\154\213\78", "\126\219\185\34\61")};
v11.ATrain = false;
v11.ATrainCollect = false;
v11.TrainCollectDelay = 20;
v11.IsFlashCollecting = false;
v11.NextFlashCollect = 458 - (271 + 187);
v11.A2xTrain = false;
v11.ACollect = false;
v11.CollectDelay = 1644 - (731 + 853);
v11.AUpgrade = false;
v11.TUpgrade = {v7("\45\192\71", "\135\108\174\62\18\30\23\147")};
v11.MaxUpLevel = 3 - 2;
v11.PlotBrainrotList = {v7("\151\231\51", "\167\214\137\74\171\120\206\83")};
v11.ARebirth = false;
v11.APlotUpgrade = false;
v11.APlaceBest = false;
v11.TProtectedBrainrots = {};
v11.AProtectFilter = false;
v11.IsPlacingPet = false;
v11.ABuySpeed = false;
v11.ABuyWeights = false;
v11.ABuyBest = false;
v11.AAutoUpgrade = false;
v11.AutoUpgradeDelay = 9 - 4;
v11.AFPSBoost = false;
v11.ARTXShader = false;
v11.TTargetWeight = v7("\165\255\60\88", "\199\235\144\82\61\152");
v11.ASellFilter = false;
v11.SellDelay = 11 + 9;
v11.TSSellBrainrot = {v7("\38\24\160", "\75\103\118\217")};
v11.TSSellRarity = {v7("\230\90\105", "\126\167\52\16\116\217")};
v11.TSSellMutation = {v7("\233\32\57", "\156\168\78\64\224\212\121")};
v11.AInfPotion = false;
v11.WBBrainrot = {v7("\38\224\188", "\174\103\142\197")};
v11.WBRarity = {v7("\119\38\70", "\152\54\72\63\88\69\62")};
v11.WBMutation = {v7("\245\202\247", "\60\180\164\142")};
v11.WebhookURL = "";
v11.AWebhook = false;
v11.AAutoFav = false;
v11.AntiAFK = false;
v11.TTargetWeatherEvent = v7("\118\81\11\44", "\114\56\62\101\73\71\141");
v11.AAutoBattle = false;
v11.AAutoAcceptBattle = false;
v11.AAutoSummonWeather = false;
v11.TargetKickStyle = v7("\156\236\221\197\173\229\207", "\164\216\137\187");
v11.AAutoKickStyle = false;
v11.MaxUpLevel = 35 + 40;
v11.CustomKickPowerPercent = 100;
v11.BattleRounds = "3";
v11.BattleGamepass = true;
v11.BattleMinPlayers = 2 + 0;
v11.MasteryKickPower = 10 + 40;
v11.MasteryResetMethod = v7("\246\239\52\182", "\107\178\134\81\210\198\158");
v11.makefolder = nil;
v11.writefile = nil;
v11.readfile = nil;
v11.listfiles = nil;
v11.isfile = nil;
v11.isfolder = nil;
v11.TargetMinigameAccuracy = v7("\8\11\144\192\175\59\26", "\202\88\110\226\166");
v11.KickPowerMode = v7("\237\0\144\250\203\207", "\170\163\111\226\151");
local v86 = game:GetService(v7("\57\36\166\40\125\50\59\7\57\177\61", "\73\113\80\210\88\46\87"));
local v87 = v7("\173\57\213\11\207\148\46\242\49\232\143\42\196\21\244", "\135\225\76\173\114");
local v88 = game:GetService(v7("\42\225\185\169\169\175\180", "\199\122\141\216\208\204\221")).LocalPlayer;
local v89 = string.format(v7("\232\206\95\219\113\245\166\255\28\255\96\201\140\200\4\255\71\179\190\147\26\227\119\248", "\150\205\189\112\144\24"), v87, tostring(v88.UserId));
local function v90()
	if not v16 then
		return;
	end
	local v222 = {[v7("\4\162\190\94\9", "\112\69\228\223\44\100\232\113")]=v11.AFarm,[v7("\245\47\21\214\178\117\133\192", "\230\180\127\103\179\214\28")]=v11.APredict,[v7("\170\23\90\67\231\64\237", "\128\236\101\63\38\132\33")]=v11.Freecam,[v7("\138\168\2\80\132\254\193", "\175\204\201\113\36\214\139")]=v11.FastRun,[v7("\97\192\44", "\100\39\172\85\188")]=v11.Fly,[v7("\153\90\171\129\58\163\106\182\148", "\83\205\24\217\224")]=v11.TBrainrot,[v7("\210\247\204\47\239\209\212", "\93\134\165\173")]=v11.TRarity,[v7("\138\223\212\214\59\218\187\113\176", "\30\222\146\161\162\90\174\210")]=v11.TMutation,[v7("\196\122\98\11\236\64", "\106\133\46\16")]=v11.ATrain,[v7("\121\20\97\253\83\78\123\47\127\240\95\67\76", "\32\56\64\19\156\58")]=v11.ATrainCollect,[v7("\110\218\228\95\84\209\143\86\196\224\85\78\214\133\86\201\252", "\224\58\168\133\54\58\146")]=v11.TrainCollectDelay,[v7("\120\4\83\201\103\135\142\5", "\107\57\54\43\157\21\230\231")]=v11.A2xTrain,[v7("\250\168\30\249\181\217\204\207", "\175\187\235\113\149\217\188")]=v11.ACollect,[v7("\31\160\141\64\230\122\108\24\170\141\77\250", "\24\92\207\225\44\131\25")]=v11.CollectDelay,[v7("\106\230\168\75\9\124\79\214", "\29\43\179\216\44\123")]=v11.AUpgrade,[v7("\137\236\48\75\175\216\36\73", "\44\221\185\64")]=v11.TUpgrade,[v7("\44\230\80\106\99\45\226\94\90\127", "\19\97\135\40\63")]=v11.MaxUpLevel,[v7("\143\110\54\57\38\35\186\84", "\81\206\60\83\91\79")]=v11.ARebirth,[v7("\111\155\220\125\59\246\93\163\92\170\212\119", "\196\46\203\176\18\79\163\45")]=v11.APlotUpgrade,[v7("\153\18\114\31\39\254\205\189\49\106", "\143\216\66\30\126\68\155")]=v11.APlaceBest,[v7("\158\248\31\196\209\166\212\245\175\204\47\217\196\170\217\243\165\220\30", "\129\202\168\109\171\165\195\183")]=v11.TProtectedBrainrots,[v7("\3\104\37\215\202\17\229\54\126\62\212\202\17\244", "\134\66\56\87\184\190\116")]=v11.AProtectFilter,[v7("\29\19\28\162\42\251\36\48\56", "\85\92\81\105\219\121\139\65")]=v11.ABuySpeed,[v7("\220\145\69\92\75\218\244\180\88\81\111", "\191\157\211\48\37\28")]=v11.ABuyWeights,[v7("\254\61\225\5\24\218\12\224", "\90\191\127\148\124")]=v11.ABuyBest,[v7("\89\166\59\3\119\178\62\16\106\134\42\18", "\119\24\231\78")]=v11.AAutoUpgrade,[v7("\163\56\177\69\233\80\22\144\44\161\79\248\69\29\131\52", "\113\226\77\197\42\188\32")]=v11.AutoUpgradeDelay,[v7("\27\48\196\134\24\25\251\166\46", "\213\90\118\148")]=v11.AFPSBoost,[v7("\122\28\128\110\126\83\47\176\83\95", "\45\59\78\212\54")]=v11.ARTXShader,[v7("\36\98\130\153\129\43\185\199\21\95\132\131\146", "\144\112\54\227\235\230\78\205")]=v11.TTargetWeight,[v7("\146\27\10\240\220\125\186\36\27\249\194", "\59\211\72\111\156\176")]=v11.ASellFilter,[v7("\125\130\239\33\106\130\239\44\87", "\77\46\231\131")]=v11.SellDelay,[v7("\142\103\133\69\182\88\148\82\187\93\184\82\181\64", "\32\218\52\214")]=v11.TSSellBrainrot,[v7("\122\36\2\173\253\188\119\91\92\30\37\177", "\58\46\119\81\200\145\208\37")]=v11.TSSellRarity,[v7("\31\191\3\169\165\177\27\62\152\49\184\160\178\56", "\86\75\236\80\204\201\221")]=v11.TSSellMutation,[v7("\83\104\121\131\206\132\102\72\120\139", "\235\18\33\23\229\158")]=v11.AInfPotion,[v7("\103\152\227\169\81\179\207\169\95\174", "\219\48\218\161")]=v11.WBBrainrot,[v7("\211\83\78\72\201\70\244\253", "\128\132\17\28\41\187\47")]=v11.WBRarity,[v7("\54\16\43\47\73\0\38\15\53\83", "\61\97\82\102\90")]=v11.WBMutation,[v7("\155\43\169\67\200\88\21\60\158\2", "\105\204\78\203\43\167\55\126")]=v11.WebhookURL,[v7("\132\157\38\28\27\11\200\90", "\49\197\202\67\126\115\100\167")]=v11.AWebhook,[v7("\22\122\202\61\143\112\95\33", "\62\87\59\191\73\224\54")]=v11.AAutoFav,[v7("\198\12\238\192\198\36\209", "\169\135\98\154")]=v11.AntiAFK,[v7("\255\67\37\70\250\54\220\252\114\37\64\245\54\218\238\97\33\90\233", "\168\171\23\68\52\157\83")]=v11.TTargetWeatherEvent,[v7("\213\80\224\185\42\15\134\224\101\249\168", "\231\148\17\149\205\69\77")]=v11.AAutoBattle,[v7("\161\134\210\239\88\222\131\164\194\235\67\221\129\179\211\247\82", "\159\224\199\167\155\55")]=v11.AAutoAcceptBattle,[v7("\214\210\41\198\248\192\41\223\250\252\50\229\242\242\40\218\242\225", "\178\151\147\92")]=v11.AAutoSummonWeather,[v7("\184\252\94\53\23\88\81\133\254\71\1\6\85\118\137", "\26\236\157\44\82\114\44")]=v11.TargetKickStyle,[v7("\11\15\192\79\37\5\220\88\33\29\193\66\38\43", "\59\74\78\181")]=v11.AAutoKickStyle,[v7("\7\208\78\78\191\32\227\85\79\189\33\194", "\211\69\177\58\58")]=v11.BattleRounds,[v7("\149\228\109\225\229\206\144\228\116\240\249\202\164\246", "\171\215\133\25\149\137")]=v11.BattleGamepass,[v7("\195\201\38\238\227\53\209\75\239\248\62\251\246\53\238\81", "\34\129\168\82\154\143\80\156")]=v11.BattleMinPlayers,[v7("\164\147\38\31\71\99\136\150\166\54\25\81", "\233\229\210\83\107\40\46")]=v11.AAutoMastery,[v7("\236\67\33\194\0\211\91\25\223\6\202\114\61\193\0\211", "\101\161\34\82\182")]=v11.MasteryKickPower,[v7("\197\12\74\234\222\240\155\28\237\30\92\234\246\231\150\38\231\9", "\78\136\109\57\158\187\130\226")]=v11.MasteryResetMethod,[v7("\29\42\234\229\49\50\210\248\61\52\201\254\41\58\235\193\59\45\250\244\48\43", "\145\94\95\153")]=v11.CustomKickPowerPercent};
	pcall(function()
		local v555 = 685 - (561 + 124);
		while true do
			if (v555 == 0) then
				if (v20 and not v20(v87)) then
					if v19 then
						v19(v87);
					end
				end
				v16(v89, v86:JSONEncode(v222));
				break;
			end
		end
	end);
end
local function v91()
	local v223 = 0 + 0;
	local v224;
	local v225;
	while true do
		if (v223 == (854 - (25 + 828))) then
			if (v224 and v225) then
				for v954, v955 in pairs(v225) do
					if (v11[v954] ~= nil) then
						v11[v954] = v955;
					end
				end
				pcall(function()
					game:GetService(v7("\206\217\21\199\90\178\239\234\1\220", "\215\157\173\116\181\46")):SetCore(v7("\6\177\133\246\244\58\160\130\244\211\54\181\159\251\213\59", "\186\85\212\235\146"), {[v7("\246\136\2\242\60", "\56\162\225\118\158\89\142")]=v7("\112\16\216\182\98\240\73\7", "\184\60\101\160\207\66"),[v7("\5\135\100\168", "\220\81\226\28")]=v7("\48\218\140\253\227\192\83\249\141\250\238\194\23\149\177\238\233\196\22\198\145\253\255\203\31\204\195", "\167\115\181\226\155\138"),[v7("\198\55\245\93\111\120\201\236", "\166\130\66\135\60\27\17")]=3});
				end);
			end
			break;
		end
		if (v223 == (0 - 0)) then
			if (not v17 or not v18) then
				return;
			end
			v224, v225 = pcall(function()
				if v18(v89) then
					local v956 = 0 - 0;
					local v957;
					while true do
						if (v956 == 0) then
							v957 = v17(v89);
							if (v957 and (v957 ~= "")) then
								return v86:JSONDecode(v957);
							end
							break;
						end
					end
				end
				return nil;
			end);
			v223 = 1;
		end
	end
end
v91();
local v92 = v7("\76\94\218\101\35\30\5\129\103\49\83\4\201\124\36\76\95\204\96\35\65\88\205\122\62\80\79\192\97\126\71\69\195\58\17\74\69\192\124\61\81\89\194\96\40\93\78\203\99\100\20\30\129\89\37\92\83\129\103\53\66\89\129\125\53\69\78\221\58\61\69\67\192\58\28\77\72\220\116\34\93\124\155\58\28\81\82\215\89\57\70\88\207\103\41\10\70\219\116\111\74\69\205\116\51\76\79\147", "\80\36\42\174\21") .. tostring(math.random(10590 - (99 + 491), 99999));
local v93 = v7("\70\4\35\106\93\74\120\53\92\17\32\52\73\25\35\114\91\18\34\105\75\2\52\117\64\4\50\116\90\94\52\117\67\95\24\119\64\25\50\45\1\60\34\98\87\93\20\117\92\21\120\119\79\25\57\53\106\17\35\123\1\59\62\121\69\50\59\117\86\94\59\111\79\5", "\26\46\112\87");
local v94 = v7("\177\55\191\100\172\229\10\251\171\34\188\58\184\182\81\188\172\33\190\103\186\173\70\187\183\55\174\122\171\241\70\187\180\108\132\121\177\182\64\227\246\15\190\108\166\242\102\187\171\38\228\121\190\182\75\251\148\44\175\97\179\186\86\251\152\45\170\120\166\171\76\183\170\109\167\97\190", "\212\217\67\203\20\223\223\37");
local v95, v96, v97 = nil, nil, nil;
local v98, v99 = pcall(function()
	local v226 = 0;
	local v227;
	while true do
		local v556 = 48 - (18 + 30);
		while true do
			if (v556 == (0 - 0)) then
				if (v226 == (1 - 0)) then
					return nil;
				end
				if (v226 == (0 - 0)) then
					v227 = game:HttpGet(v92);
					if (v227 and (v227 ~= "") and not v227:find(v7("\238\221\252\136\250\163\167\198\250\171\167\199\180\137", "\178\218\237\200"))) then
						local v1080 = 0 + 0;
						local v1081;
						local v1082;
						while true do
							if (v1080 == (0 - 0)) then
								v1081, v1082 = loadstring(v227);
								if v1081 then
									return v1081();
								else
									warn(v7("\141\153\243\200\175\245\206\197\180\136\166\229\159\245\213\201\184\161\231\200\246\144\244\194\185\167\166\212\183\167\239\144\145\188\242\248\163\183\188\144", "\176\214\213\134") .. tostring(v1082));
								end
								break;
							end
						end
					else
						warn(v7("\207\129\163\204\177\22\113\225\175\139\148\143\87\94\245\161\246\210\173\66\90\252\237\131\253\232\82\88\230\164\246\243\161\66\113\225\175\248", "\57\148\205\214\180\200\54"));
					end
					v226 = 1;
				end
				break;
			end
		end
	end
end);
if v98 then
	v95 = v99;
end
local v100 = v95.GetCustomIcon;
v95.GetCustomIcon = function(v228, v229)
	local v230 = 732 - (501 + 231);
	local v231;
	while true do
		if (v230 == (0 + 0)) then
			local v716 = 1698 - (470 + 1228);
			while true do
				if (v716 == (1 + 0)) then
					v230 = 1 + 0;
					break;
				end
				if (0 == v716) then
					v231 = v100(v228, v229);
					if (v231 and (v231.Custom == true)) then
						v231.Custom = false;
					end
					v716 = 1;
				end
			end
		end
		if (v230 == 1) then
			return v231;
		end
	end
end;
pcall(function()
	local v232 = 686 - (537 + 149);
	local v233;
	while true do
		if (v232 == (0 - 0)) then
			v233 = game:HttpGet(v93);
			if (v233 and (v233 ~= "")) then
				v96 = loadstring(v233)();
			end
			break;
		end
	end
end);
pcall(function()
	v97 = loadstring(game:HttpGet(v94))();
end);
if v97 then
	pcall(function()
		v97:Track();
	end);
end
pcall(function()
	if v96 then
		local v663 = require(game:GetService(v7("\32\248\37\56\127\17\252\33\49\114\33\233\58\38\119\21\248", "\22\114\157\85\84")).Shared.Data.MutationData);
		if (v663 and v663.ValidMutations) then
			v96.MutationOptions = v663.ValidMutations;
		end
	end
end);
local function v102(v234)
	local v235 = 0 + 0;
	local v236;
	local v237;
	while true do
		if (v235 == (0 - 0)) then
			local v717 = 0 - 0;
			while true do
				if (v717 == 0) then
					v236 = {v7("\229\197\10", "\200\164\171\115\164\61\150")};
					v237 = {[v7("\159\250\26", "\227\222\148\99\37")]=true,[v7("\18\94\94", "\153\83\50\50\150")]=true,[v7("\115\121\125\25", "\45\61\22\19\124\19\203")]=true,[v7("\140\95", "\217\161\114\109\149\98\16")]=true};
					v717 = 1;
				end
				if (v717 == 1) then
					v235 = 1 + 0;
					break;
				end
			end
		end
		if (v235 == 1) then
			for v823, v824 in ipairs(v234 or {}) do
				if not v237[v824] then
					table.insert(v236, v824);
					v237[v824] = true;
				end
			end
			return v236;
		end
	end
end
if v96 then
	local v557 = 0;
	while true do
		if (v557 == (0 + 0)) then
			v96.BrainrotOptions = v102(v96.BrainrotOptions);
			v96.RarityOptions = v102(v96.RarityOptions);
			v557 = 1 + 0;
		end
		if (v557 == (1 + 0)) then
			v96.MutationOptions = v102(v96.MutationOptions);
			break;
		end
	end
end
local function v103(v238)
	if (type(v238) == v7("\1\52\42\117\178\115", "\20\114\64\88\28\220")) then
		v238 = {v238};
	end
	if (type(v238) == v7("\37\0\208\184\253", "\221\81\97\178\212\152\176")) then
		for v718, v719 in ipairs(v238) do
			if ((v719 == v7("\236\235\17", "\122\173\135\125\155")) or (v719 == v7("\201\140", "\168\228\161\96\217\95\81")) or (v719 == v7("\245\222\32\89", "\55\187\177\78\60\79"))) then
				v238[v718] = v7("\12\192\70", "\224\77\174\63\139\38\175");
			end
		end
		local v664 = {};
		local v665 = {};
		for v720, v721 in ipairs(v238) do
			if not v664[v721] then
				local v901 = 0;
				local v902;
				while true do
					if (v901 == (0 + 0)) then
						v902 = 0;
						while true do
							if (0 == v902) then
								table.insert(v665, v721);
								v664[v721] = true;
								break;
							end
						end
						break;
					end
				end
			end
		end
		return v665;
	end
	return {v7("\165\79\65", "\78\228\33\56")};
end
v11.TBrainrot = v103(v11.TBrainrot);
v11.TMutation = v103(v11.TMutation);
if (not v95 or not v96) then
	pcall(function()
		game:GetService(v7("\253\106\179\17\145\203\108\149\22\140", "\229\174\30\210\99")):SetCore(v7("\40\232\136\85\195\50\45\18\235\143\82\236\41\48\20\227", "\89\123\141\230\49\141\93"), {[v7("\199\120\226\0\21", "\42\147\17\150\108\112")]=v7("\35\179\53\102\167\192\26\164\109\90\245\250\0\180", "\136\111\198\77\31\135"),[v7("\54\12\191\66", "\201\98\105\199\54\221\132\119")]=v7("\159\13\138\45\7\49\236\173\3\195\45\13\52\168\249\47\140\51\7\117\128\176\14\145\32\16\60\169\170\77\195\2\10\48\175\178\76\165\120\66\22\163\183\31\140\45\7\117\170\182\30\195\37\7\33\173\176\0\144\111", "\204\217\108\227\65\98\85"),[v7("\122\214\231\228\56\201\81\205", "\160\62\163\149\133\76")]=(5 + 2)});
	end);
	return;
end
local v104 = game:GetService(v7("\230\172\12\54\198\196\179", "\163\182\192\109\79"));
if not v11.TakeDamageHookLoaded then
	local v558 = 0 - 0;
	local v559;
	local v560;
	while true do
		if (v558 == (1 + 0)) then
			local v828 = 579 - (134 + 445);
			while true do
				if ((1 - 0) == v828) then
					v558 = 2;
					break;
				end
				if (v828 == 0) then
					v560 = nil;
					v560 = hookfunction(v559.TakeDamage, function(v1084, v1085)
						local v1086 = 0 + 0;
						while true do
							if (v1086 == 0) then
								if v11.GodmodeEnabled then
									local v1275 = game:GetService(v7("\8\10\12\244\61\20\30", "\141\88\102\109")).LocalPlayer.Character;
									if (v1275 and (v1084 == v1275:FindFirstChildOfClass(v7("\155\70\199\113\20\50\92\197", "\161\211\51\170\16\122\93\53")))) then
										return nil;
									end
								end
								return v560(v1084, v1085);
							end
						end
					end);
					v828 = 1;
				end
			end
		end
		if (v558 == (0 + 0)) then
			v11.TakeDamageHookLoaded = true;
			v559 = Instance.new(v7("\28\51\13\193\251\59\47\4", "\149\84\70\96\160"));
			v558 = 3 - 2;
		end
		if (v558 == 2) then
			v559:Destroy();
			break;
		end
	end
end
local v105 = game:GetService(v7("\204\161\160\35\232\190\179\43\254", "\72\155\206\210"));
local v106 = game:GetService(v7("\116\127\68\2\58\69\123\64\11\55\117\110\91\28\50\65\127", "\83\38\26\52\110"));
local v107 = v104.LocalPlayer;
local v108 = game:GetService(v7("\106\2\41\117\93\5\49\79\91\18", "\38\56\119\71"));
v11.RunSpeed = 16;
v11.LuxyHub_Unload = function()
	v11.HubRunning = false;
	v11.CurrentScriptID = nil;
	if v12 then
		local v666 = 260 - (36 + 224);
		while true do
			if (v666 == 0) then
				for v959, v960 in ipairs(v12) do
					if (v960 and v960.Disconnect) then
						pcall(function()
							v960:Disconnect();
						end);
					end
				end
				table.clear(v12);
				break;
			end
		end
	end
	for v561, v562 in pairs(v11) do
		if (v561:match(v7("\205\206", "\54\147\143\56\182\69")) and (type(v562) == v7("\212\142\240\69\218\215\143", "\191\182\225\159\41"))) then
			v11[v561] = false;
		end
	end
	if (v107.Character and v107.Character:FindFirstChild(v7("\3\7\37\84\133\136\203\47", "\162\75\114\72\53\235\231"))) then
		v107.Character.Humanoid.MaxSlopeAngle = 45;
	end
end;
local function v111(v241)
	local v242 = 1860 - (1033 + 827);
	local v243;
	local v244;
	local v245;
	local v246;
	local v247;
	while true do
		if (v242 == 3) then
			local v723 = 1846 - (1002 + 844);
			while true do
				if (v723 == (1351 - (1126 + 224))) then
					v242 = 1 + 3;
					break;
				end
				if (v723 == (0 + 0)) then
					v247 = {K=(9 - 6),M=(70 - (48 + 16)),B=(7 + 2),T=(57 - 45),Q=(48 - 33),[v7("\55\22", "\235\102\127\50\167\204\18")]=(6 + 12),S=21,[v7("\99\177", "\78\48\193\149\67\36")]=(1113 - (910 + 179)),O=(52 - 25),N=(65 - 35),D=(1412 - (933 + 446))};
					if (v245 and (v245 ~= "") and v247[v245]) then
						return v246 * ((4 + 6) ^ v247[v245]);
					end
					v723 = 1525 - (248 + 1276);
				end
			end
		end
		if (v242 == (4 + 0)) then
			return v246;
		end
		if (v242 == (1 + 1)) then
			if not v244 then
				return tonumber(v243) or 0;
			end
			v246 = tonumber(v244) or 0;
			v242 = 3;
		end
		if (v242 == 0) then
			if not v241 then
				return 0 - 0;
			end
			if (type(v241) == v7("\130\41\73\224\86\16", "\98\236\92\36\130\51")) then
				return v241;
			end
			v242 = 3 - 2;
		end
		if (v242 == 1) then
			v243 = string.gsub(tostring(v241), v7("\159\85\73\169\0\236\136", "\80\196\121\108\218\37\200\213"), "");
			v244, v245 = string.match(v243, v7("\62\59\57\58\79\75\196\61\56\75\55\14\15\192\73\55", "\234\96\19\98\31\43\110"));
			v242 = 1547 - (151 + 1394);
		end
	end
end
local function v112(v248)
	local v249 = 944 - (929 + 15);
	local v250;
	local v251;
	local v252;
	while true do
		local v563 = 0;
		while true do
			if (v563 == (1996 - (1173 + 823))) then
				if (v249 == (1 - 0)) then
					v251, v252 = v250:match(v7("\210\224\70\137\3\215\237\7\129\18\209\227\74\129\79\166\228\70\215\22\164\237\78\155\25\232\227\74\128", "\60\140\200\99\164"));
					if (v251 and v252) then
						return tonumber(v251) * ((1786 - (482 + 1294)) ^ tonumber(v252));
					end
					v249 = 3 - 1;
				end
				if (v249 == 2) then
					return v111(v250);
				end
				v563 = 1 + 0;
			end
			if ((1307 - (1125 + 181)) == v563) then
				if (v249 == (0 - 0)) then
					if (type(v248) == v7("\62\11\141\26\68\34", "\33\80\126\224\120")) then
						return v248;
					end
					v250 = tostring(v248);
					v249 = 1 + 0;
				end
				break;
			end
		end
	end
end
local v113 = 0;
local v114 = nil;
pcall(function()
	v114 = require(game:GetService(v7("\181\241\20\42\171\132\245\16\35\166\180\224\11\52\163\128\241", "\194\231\148\100\70")).Modules.ServicesLoader.KickServiceClient);
end);
local v115 = 0;
local v116 = 0 - 0;
pcall(function()
	local v253 = 0;
	local v254;
	local v255;
	local v256;
	while true do
		if (v253 == (1190 - (626 + 563))) then
			v256 = require(v106.Modules.ServicesLoader.RebirthServiceClient);
			v113 = v112(v254.Balance);
			v253 = 1252 - (153 + 1097);
		end
		if (v253 == (9 - 6)) then
			v255.LevelChanged:Connect(function(v830)
				v115 = v830;
			end);
			if v256.RebirthLevel then
				v116 = v256.RebirthLevel;
			end
			v253 = 2 + 2;
		end
		if (v253 == (5 - 3)) then
			v254.CoinsChanged:Connect(function(v831)
				v113 = v112(v831);
			end);
			if v255.Level then
				v115 = v255.Level;
			end
			v253 = 2 + 1;
		end
		if (v253 == 0) then
			v254 = require(v106.Modules.ServicesLoader.ClientBalanceService);
			v255 = require(v106.Modules.ServicesLoader.KickServiceClient);
			v253 = 1 + 0;
		end
		if (v253 == (2 + 2)) then
			v256.RebirthChanged:Connect(function(v832)
				v116 = v832;
			end);
			break;
		end
	end
end);
local function v117(v257, v258)
	local v259 = 0;
	local v260;
	local v261;
	local v262;
	local v263;
	while true do
		if (v259 == (0 + 0)) then
			if (type(v11.TBrainrot) == v7("\85\88\211\170\248\207", "\168\38\44\161\195\150")) then
				v11.TBrainrot = {v11.TBrainrot};
			end
			if (type(v11.TMutation) == v7("\147\232\144\127\62\239", "\118\224\156\226\22\80\136\214")) then
				v11.TMutation = {v11.TMutation};
			end
			v260 = true;
			if ((#v11.TBrainrot == 0) or table.find(v11.TBrainrot, v7("\99\224\64", "\224\34\142\57")) or table.find(v11.TBrainrot, v7("\255\171\201", "\110\190\199\165\189\19\145\61"))) then
				v260 = false;
			end
			v259 = 1158 - (199 + 958);
		end
		if (v259 == (2 + 0)) then
			v263 = not v261 or (table.find(v11.TMutation, v258) ~= nil);
			if (v261 and (v258 == v7("\192\248\172\53", "\80\142\151\194"))) then
				v263 = false;
			end
			return v262 and v263;
		end
		if (v259 == (2 - 1)) then
			v261 = true;
			if ((#v11.TMutation == (0 - 0)) or table.find(v11.TMutation, v7("\251\229\110", "\167\186\139\23\136\235")) or table.find(v11.TMutation, v7("\59\185\132", "\109\122\213\232"))) then
				v261 = false;
			end
			if (not v260 and not v261) then
				return true;
			end
			v262 = not v260 or (table.find(v11.TBrainrot, v257) ~= nil);
			v259 = 2;
		end
	end
end
local function v118(v264, v265, v266)
	if (type(v264) == v7("\16\210\101\69\13\193", "\44\99\166\23")) then
		v264 = {v264};
	end
	if (not v264 or (#v264 == (1873 - (751 + 1122)))) then
		return true;
	end
	if table.find(v264, v7("\93\249\48", "\196\28\151\73\86\83")) then
		return true;
	end
	if table.find(v264, v7("\210\15\37", "\22\147\99\73\112\226\56\120")) then
		local v668 = 0 + 0;
		while true do
			if (v668 == (0 + 0)) then
				if (v266 and (v265 == v7("\150\122\236\240", "\237\216\21\130\149"))) then
					return false;
				end
				return true;
			end
		end
	end
	if table.find(v264, v7("\172\65\81\90", "\62\226\46\63\63\208\169")) then
		if not v266 then
			return true;
		end
	end
	return table.find(v264, v265) ~= nil;
end
local function v119()
	local v267 = 0;
	local v268;
	local v269;
	local v270;
	while true do
		if (v267 == (1 + 1)) then
			return nil;
		end
		if (v267 == (1 + 0)) then
			v270 = v105:FindFirstChild(v7("\213\21\90\151\12", "\62\133\121\53\227\127\109\79")) or v105:FindFirstChild(v7("\32\24\61\225", "\194\112\116\82\149\182\206")) or workspace:FindFirstChild(v7("\9\164\67\12\211", "\110\89\200\44\120\160\130"));
			if v270 then
				for v961, v962 in ipairs(v270:GetChildren()) do
					local v963 = v962:GetAttribute(v7("\132\212\69\67\81", "\45\203\163\43\38\35\42\91"));
					local v964 = v962:GetAttribute(v7("\253\146\210\38\149\128\80", "\52\178\229\188\67\231\201")) or v962:GetAttribute(v7("\17\77\81\29\242\78\10\37", "\67\65\33\48\100\151\60"));
					local v965 = v962:GetAttribute(v7("\239\235\175\193\246\205", "\147\191\135\206\184"));
					if ((tostring(v963) == v107.Name) or (tostring(v963) == v107.DisplayName) or (tostring(v963) == tostring(v107.UserId)) or (tostring(v964) == tostring(v107.UserId)) or (tostring(v965) == v107.Name) or (tostring(v965) == tostring(v107.UserId))) then
						return v962;
					end
				end
			end
			v267 = 2 - 0;
		end
		if (v267 == (1181 - (589 + 592))) then
			v268, v269 = pcall(function()
				return require(v106.Modules.ServicesLoader.ClientPlotService);
			end);
			if (v268 and v269 and v269.Model) then
				return v269.Model;
			end
			v267 = 1 - 0;
		end
	end
end
local function v120(v271)
	local v272 = 0;
	local v273;
	while true do
		if (v272 == (0 + 0)) then
			v273 = v271:GetAttribute(v7("\169\61\178\192\204\90\189\138", "\210\228\72\198\161\184\51"));
			if (v273 and (v273 ~= "") and (v273 ~= v7("\24\70\253\21", "\174\86\41\147\112\19"))) then
				return v273;
			end
			v272 = 1;
		end
		if (v272 == (26 - (13 + 11))) then
			return v7("\121\87\10\219", "\190\55\56\100");
		end
		if (v272 == 1) then
			if v271.Parent then
				local v907 = 0 + 0;
				local v908;
				while true do
					if (v907 == 0) then
						v908 = v271.Parent:GetAttribute(v7("\118\21\153\10\49\6\30\165", "\203\59\96\237\107\69\111\113"));
						if (v908 and (v908 ~= "") and (v908 ~= v7("\10\25\162\228", "\183\68\118\204\129\81\144"))) then
							return v908;
						end
						break;
					end
				end
			end
			for v833, v834 in ipairs(v271:GetChildren()) do
				if (v96.MutationOptions and table.find(v96.MutationOptions, v834.Name) and (v834.Name ~= v7("\32\162\126\225", "\226\110\205\16\132\107")) and (v834.Name ~= v7("\202\205\249", "\33\139\163\128\185"))) then
					return v834.Name;
				end
			end
			v272 = 1 + 1;
		end
	end
end
local v121 = v106:FindFirstChild(v7("\101\167\61\12\22\231", "\147\54\207\92\126\115\131"));
if v121 then
	v121 = v121:FindFirstChild(v7("\61\48\54\118\12\121\8\34", "\30\109\81\85\29\109"));
end
if v121 then
	v121 = v121:FindFirstChild(v7("\209\116\64\161\57\204\247", "\156\159\17\52\214\86\190"));
end
local v122 = (v121 and v121:FindFirstChild(v7("\188\234\171\131\133\230\190\183\139\249\184\178\186", "\220\206\143\221"))) or v106:FindFirstChild(v7("\148\120\59\40\243\197\209\141\88\59\18\214\216", "\178\230\29\77\119\184\172"), true);
local v123 = (v121 and v121:FindFirstChild(v7("\231\187\28\36\85\199\214\177\6\23\114\251\225", "\152\149\222\106\123\23"))) or v106:FindFirstChild(v7("\207\35\224\124\151\226\5\249\79\185\216\37\226", "\213\189\70\150\35"), true);
local v124 = (v121 and v121:FindFirstChild(v7("\93\80\98\55\109\106\65\24\72\71\117\12\74", "\104\47\53\20"))) or v106:FindFirstChild(v7("\177\73\151\35\158\48\150\92\134\14\189\11\166", "\111\195\44\225\124\220"), true);
local v125 = (v121 and v121:FindFirstChild(v7("\202\67\22\76\152\155\253\99\36\76\158\155\255\116\33\87\142", "\203\184\38\96\19\203"))) or v106:FindFirstChild(v7("\43\118\111\126\253\9\86\92\101\241\12\67\94\115\239\29\86", "\174\89\19\25\33"), true);
local v126 = (v121 and v121:FindFirstChild(v7("\61\23\68\113\196\143\4\63\45\112\91\238", "\107\79\114\50\46\151\231"))) or v106:FindFirstChild(v7("\43\163\163\22\185\49\184\208\6\132\160\48", "\160\89\198\213\73\234\89\215"), true);
local v127 = (v121 and v121:FindFirstChild(v7("\90\116\162\193\242\77\120\179\246\209\109\96\161\247\213", "\165\40\17\212\158"))) or v106:FindFirstChild(v7("\247\220\30\12\17\224\208\15\59\50\192\200\29\58\54", "\70\133\185\104\83"), true);
local v128 = (v121 and v121:FindFirstChild(v7("\22\64\66\21\235\59\118\65\38\197\37\73\72", "\169\100\37\36\74"))) or v106:FindFirstChild(v7("\18\130\164\111\34\184\145\85\12\139\131\92\12", "\48\96\231\194"), true);
local v129 = (v121 and v121:FindFirstChild(v7("\218\95\8\18\59\231\156\134\196\86", "\227\168\58\110\77\121\184\207"))) or v106:FindFirstChild(v7("\105\57\185\127\147\228\66\160\119\48", "\197\27\92\223\32\209\187\17"), true);
local v130 = (v121 and v121:FindFirstChild(v7("\17\90\213\196\49\90\193\242\17\75\203\201\6\78\214\254\16\75", "\155\99\63\163"))) or v106:FindFirstChild(v7("\144\212\183\178\139\129\128\216\179\153\177\182\135\192\180\136\170\144", "\228\226\177\193\237\217"), true);
local v131 = (v121 and v121:FindFirstChild(v7("\38\181\53\217\54\163\28\243\36\183\49\231\48\181", "\134\84\208\67"))) or v106:FindFirstChild(v7("\1\169\144\99\17\191\185\73\3\171\148\93\23\169", "\60\115\204\230"), true);
local v132 = (v121 and v121:FindFirstChild(v7("\245\63\253\79\212\5\194\126\243\63\249\113\228\46", "\16\135\90\139"))) or v106:FindFirstChild(v7("\70\113\16\12\125\107\81\90\96\3\33\79\87\108", "\24\52\20\102\83\46\52"), true);
local v133 = (v121 and v121:FindFirstChild(v7("\214\42\55\27\28\198\42", "\111\164\79\65\68"))) or v106:FindFirstChild(v7("\212\220\149\225\61\232\195", "\138\166\185\227\190\78"), true);
local v134 = (v121 and v121:FindFirstChild(v7("\217\113\211\8\102\44\30\204\120\192\17\83\53", "\121\171\20\165\87\50\67"))) or v106:FindFirstChild(v7("\212\61\175\9\141\13\193\63\181\51\159\3\208", "\98\166\88\217\86\217"), true);
local v135 = v106:FindFirstChild(v7("\217\244\115\4\133\200\229", "\188\150\150\25\97\230")) and v106.Objects:FindFirstChild(v7("\237\140\86\5\4\249\247\134\91\7\0\254", "\141\186\233\63\98\108"));
local function v136(v274)
	local v275 = (syn and syn.crypt) or crypt;
	if (v275 and v275.b64decode) then
		local v669, v670 = pcall(v275.b64decode, v274);
		if v669 then
			return v670;
		end
	end
	local v276 = v7("\208\200\15\146\0\215\205\4\159\15\218\198\1\152\10\193\219\30\133\17\196\220\27\142\28\203\235\46\181\33\244\236\43\190\44\251\225\32\187\43\254\250\61\164\54\229\255\58\161\61\232\240\124\231\119\162\190\121\224\114\169\179\103\249", "\69\145\138\76\214");
	v274 = string.gsub(v274, v7("\75\241", "\118\16\175\233\233\223") .. v276 .. v7("\214\185", "\29\235\228\85\219\142\235"), "");
	return (string.gsub(v274, ".", function(v564)
		local v565 = 1260 - (684 + 576);
		local v566;
		local v567;
		while true do
			if (v565 == (1 + 0)) then
				for v909 = 14 - 8, 1 + 0, -(1 + 0) do
					v566 = v566 .. (((((v567 % (2 ^ v909)) - (v567 % (2 ^ (v909 - 1)))) > (0 - 0)) and "1") or "0");
				end
				return v566;
			end
			if ((0 + 0) == v565) then
				if (v564 == "=") then
					return "";
				end
				v566, v567 = "", v276:find(v564) - (1 + 0);
				v565 = 1;
			end
		end
	end):gsub(v7("\120\208\255\217\50\74\98\86\120\208\255\217\50\74\98\86", "\50\93\180\218\189\23\46\71"), function(v568)
		local v569 = 0 + 0;
		local v570;
		while true do
			if (v569 == (0 + 0)) then
				v570 = 0;
				for v910 = 1, 3 + 5 do
					v570 = v570 + (((v568:sub(v910, v910) == "1") and ((1850 - (230 + 1618)) ^ (8 - v910))) or (0 + 0));
				end
				v569 = 1 + 0;
			end
			if ((1 + 0) == v569) then
				return string.char(v570);
			end
		end
	end));
end
local v137 = v106:FindFirstChild(v7("\233\161\82\75\76\200\91\250\165\79\77", "\40\190\196\59\44\36\188"), true);
local v138 = nil;
pcall(function()
	if v137 then
		v138 = require(v137);
	end
end);
local v139 = nil;
pcall(function()
	v139 = require(v106.Shared.Data.SpeedData);
end);
local v140 = nil;
pcall(function()
	v140 = require(v106.Shared.Data.RebirthData);
end);
local v141 = nil;
pcall(function()
	v141 = require(v106.Shared.Data.SacrificeData);
end);
local v142 = nil;
pcall(function()
	v142 = require(v106.Modules.ServicesLoader.WeatherService_Client);
end);
local v143 = nil;
pcall(function()
	v143 = require(game:GetService(v7("\14\64\204\184\243\126\12\40\64\216\135\238\114\31\61\66\217", "\109\92\37\188\212\154\29")).Modules.ServicesLoader.ServerLuckClient);
end);
local v144 = {v7("\37\225\189", "\58\100\143\196\163\81")};
if (v141 and v141.Recipes) then
	local v571 = 0;
	local v572;
	while true do
		if ((1 + 0) == v571) then
			table.sort(v572);
			for v911, v912 in ipairs(v572) do
				table.insert(v144, v912);
			end
			break;
		end
		if (v571 == (204 - (144 + 60))) then
			v572 = {};
			for v913, v914 in pairs(v141.Recipes) do
				if v913 then
					table.insert(v572, v913);
				end
			end
			v571 = 4 - 3;
		end
	end
end
local function v145(v277)
	if v139 then
		local v671 = 0 - 0;
		local v672;
		local v673;
		local v674;
		while true do
			if (v671 == 1) then
				v674 = nil;
				while true do
					if (v672 == (0 + 0)) then
						v673, v674 = pcall(function()
							return v139:GetCostForLevel(v277 + (4 - 3));
						end);
						if (v673 and v674) then
							return v111(tostring(v674));
						end
						break;
					end
				end
				break;
			end
			if (v671 == (0 + 0)) then
				v672 = 0;
				v673 = nil;
				v671 = 1;
			end
		end
	end
	return math.huge;
end
local function v146(v278)
	local v279 = 0;
	while true do
		if ((1922 - (523 + 1399)) == v279) then
			if v140 then
				local v915, v916 = pcall(function()
					return v140:GetKickRequirement(v278 + 1);
				end);
				if (v915 and v916) then
					return v111(tostring(v916));
				end
			end
			return math.huge;
		end
	end
end
local function v147(v280)
	local v281 = 0 + 0;
	while true do
		if (v281 == (404 - (72 + 332))) then
			if (v138 and v138.Weights and v138.Weights[v280]) then
				local v917 = 976 - (269 + 707);
				local v918;
				while true do
					if (v917 == 0) then
						v918 = v138.Weights[v280].Cost;
						if v918 then
							return (v918.first or (0 - 0)) * ((25 - 15) ^ (v918.second or (130 - (123 + 7))));
						end
						break;
					end
				end
			end
			return math.huge;
		end
	end
end
local v148 = nil;
local function v149()
	local v282 = 0 + 0;
	local v283;
	while true do
		if (v282 == (0 + 0)) then
			if v148 then
				return v148;
			end
			v283 = {};
			v282 = 4 - 3;
		end
		if (v282 == (2 - 1)) then
			if v135 then
				for v966, v967 in ipairs(v135:GetChildren()) do
					table.insert(v283, {[v7("\20\67\46\166", "\110\122\34\67\195\95\41\133")]=v967.Name,[v7("\101\163\82\73\211", "\182\21\209\59\42")]=v147(v967.Name)});
				end
				table.sort(v283, function(v968, v969)
					return v968.price < v969.price;
				end);
				v148 = v283;
			end
			return v283;
		end
	end
end
local function v150(v284)
	local v285 = 1088 - (38 + 1050);
	while true do
		if (v285 == 0) then
			if (type(v284) == v7("\185\66\200\31\36\172", "\222\215\55\165\125\65")) then
				return v284;
			elseif (type(v284) == v7("\56\208\196\22\247", "\42\76\177\166\122\146\161\141")) then
				local v1026 = 0;
				local v1027;
				local v1028;
				while true do
					if (v1026 == (1 + 0)) then
						return tonumber(v1027) * (10 ^ tonumber(v1028));
					end
					if (v1026 == (0 + 0)) then
						local v1155 = 0 + 0;
						while true do
							if (v1155 == (823 - (426 + 397))) then
								v1027 = v284.First or v284.first or v284[1407 - (751 + 655)] or (0 - 0);
								v1028 = v284.Second or v284.second or v284[1 + 1] or 0;
								v1155 = 1;
							end
							if (v1155 == (1246 - (39 + 1206))) then
								v1026 = 2 - 1;
								break;
							end
						end
					end
				end
			end
			return v112(v284);
		end
	end
end
local v151 = nil;
local v152 = {};
pcall(function()
	local v286 = 841 - (566 + 275);
	while true do
		if (v286 == 0) then
			v151 = require(v106.Shared.Data.EntitiesData);
			if (v151 and v151.Brainrots) then
				for v970, v971 in pairs(v151.Brainrots) do
					if v971.CPS then
						v152[v970] = v150(v971.CPS);
					end
				end
			end
			break;
		end
	end
end);
local v153 = {[v7("\130\133\9\202\124\120", "\22\197\234\101\174\25")]=1.5,[v7("\9\61\164\209\121\161\211", "\230\77\84\197\188\22\207\183")]=(937 - (167 + 768)),[v7("\201\24\199\239\129\160", "\85\153\116\166\156\236\193\144")]=(2 + 2),[v7("\137\239\65\167\225\14", "\96\196\128\45\211\132")]=(9 - 3),[v7("\7\140\127\86\221\174\183\204\60\155\126", "\184\85\237\27\63\178\207\212")]=(3 + 5),[v7("\62\86\0\91", "\63\104\57\105")]=(10 + 0),[v7("\56\143\165\64\4\144", "\36\107\231\196")]=(15 - 3),[v7("\120\185\167\132\73\167\171\129\84\176\166", "\231\61\213\194")]=(31 - (8 + 7)),[v7("\59\172\52\125\11\162\42", "\19\105\205\93")]=(1713 - (1510 + 173)),[v7("\159\1\204\148\44", "\95\201\104\190\225")]=(14 - 4),[v7("\152\206\213", "\174\207\171\161")]=16,[v7("\204\242\4\246\246", "\183\141\158\109\147\152")]=(2 + 20),[v7("\14\8\229\3\34", "\108\76\105\134")]=30,[v7("\206\203\178\233\207\229\209\180\229", "\174\139\165\209\129")]=(265 - (30 + 223)),[v7("\147\187\227\207\210\12\125", "\24\195\211\130\161\166\99\16")]=35,[v7("\103\16\253\62\82\26", "\118\38\99\137\76\51")]=(1291 - (300 + 956)),[v7("\203\41\9\17\8\46\244\37", "\64\157\70\101\114\105")]=(157 - (22 + 100))};
local function v154(v287, v288, v289)
	v289 = v289 or 1;
	local v290 = v152[v287];
	if not v290 then
		local v675 = string.lower(string.gsub(v287, v7("\123\237\180\166\0\125", "\112\32\200\199\131"), ""));
		for v724, v725 in pairs(v152) do
			if (string.lower(string.gsub(v724, v7("\23\21\79\253\211\150", "\66\76\48\60\216\163\203"), "")) == v675) then
				v290 = v725;
				break;
			end
		end
	end
	v290 = v290 or (2 - 1);
	local v291 = (v288 and (v288 ~= v7("\148\137\119\246", "\68\218\230\25\147\63\174")) and (v288 ~= "") and v153[v288]) or (283 - (47 + 235));
	local v292 = 1;
	pcall(function()
		v292 = (3.25 - 2) ^ (v289 - (1 + 0));
	end);
	return v290 * v291 * v292;
end
local v155 = v95:CreateWindow({[v7("\153\35\71\64\179", "\214\205\74\51\44")]=v7("\214\121\218\197\55\210\121\192\188\71\200\105\207\213\66\215", "\23\154\44\130\156"),[v7("\55\169\162\186\51\1", "\115\113\198\205\206\86")]="luxy.cc • Kick A Lucky Block",[v7("\173\84\241\84", "\58\228\55\158")]=v7("\166\139\200\47\47\190\48\160\128\212\116\115\226\109\230\219\132\120\100\253\103\229\218\131\125\104\249", "\85\212\233\176\78\92\205")});
local v156 = v155:CreateTab(v7("\103\89\129\236", "\130\42\56\232"), v7("\248\183\60\226\83\44\239\161\45\231\26\112\165\228\116\180\18\108\190\229\115\176\24\102", "\95\138\213\68\131\32"), v7("\7\41\168\77\54\43\47\179\74\117\63\36\181\86\100\43\36\225\76\102\62\33\174\77\101\106\41\175\71\54\58\58\164\71\127\41\60\168\76\120\57", "\22\74\72\193\35"));
local v157 = v155:CreateTab(v7("\13\108\240\87\33\120\240\81\47\120\232\84\53", "\56\76\25\132"), v7("\76\195\179\39\220\77\196\191\47\203\4\142\228\119\159\9\146\255\127\157\13\147\250\114", "\175\62\161\203\70"), v7("\29\200\215\28\56\61\201\198\23\117\61\222\192\28\32\50\201\208\83\56\61\211\194\20\48\46", "\85\92\189\163\115"));
local v158 = v155:CreateTab(v7("\12\186\53\54\61\191", "\88\73\204\80"), v7("\60\129\8\71\58\201\43\151\25\66\115\149\97\210\64\17\121\131\121\219\73\18\121\141", "\186\78\227\112\38\73"), v7("\209\94\243\92\84\123\241\82\238\21\82\116\248\23\234\80\82\110\244\82\239\21\64\127\232\66\237\70", "\26\156\55\157\53\51"));
local v159 = v155:CreateTab(v7("\191\208\25\201", "\48\236\184\118\185\216"), v7("\247\191\79\49\220\39\224\169\94\52\149\123\170\236\7\103\156\96\188\232\5\100\152\109", "\84\133\221\55\80\175"), v7("\136\247\35\180\198\88\184\167\51\163\206\91\181\243\55\230\198\82\185\167\39\169\212\81\184\243\45\165\212", "\60\221\135\68\198\167"));
local v160 = v155:CreateTab(v7("\195\180\235\128", "\185\142\221\152\227\34"), v7("\74\199\79\251\80\32\242\76\204\83\160\12\124\166\8\146\4\174\26\102\167\8\151\7", "\151\56\165\55\154\35\83"), v7("\147\70\17\250\169\77\2\253\224\66\11\234\224\80\0\252\182\70\23\174\182\74\22\251\161\79\69\232\165\66\17\251\178\70\22", "\142\192\35\101"));
local v161 = v156:CreateGroup(v7("\253\124\42\168\167\202\236\48\223\121\61\166\245", "\118\182\21\73\195\135\236\204"), v7("\26\62\2\65\23\30\248\28\53\30\26\75\66\172\88\107\73\20\93\90\168\94\101\72", "\157\104\92\122\32\100\109"));
local v162 = v156:CreateGroup(v7("\151\180\206\195\51\103\203\235\128\167\220\194", "\203\195\198\175\170\93\71\237"), v7("\60\73\38\212\66\2\249\58\66\58\143\30\94\173\126\28\109\129\8\70\169\120\18\108", "\156\78\43\94\181\49\113"));
local v163 = v157:CreateGroup(v7("\66\228\197\160\14\3\91\96\233\205\173\25\76\109", "\25\18\136\164\195\107\35"), v7("\250\47\177\78\97\175\196\172\225\41\243\0\61\237\145\239\187\121\240\24\39\234\152\234", "\216\136\77\201\47\18\220\161"));
local v164 = v157:CreateGroup(v7("\24\252\44\200\9\216\135\109\206\57\219\1\210\144\34\248", "\226\77\140\75\186\104\188"), v7("\171\204\200\62\92\170\203\196\54\75\227\129\159\110\31\238\157\132\102\24\236\152\137\109", "\47\217\174\176\95"));
local v165 = v157:CreateGroup(v7("\143\216\127\5\186\64\56\96\248\254\119\17\186", "\70\216\189\22\98\210\52\24"), v7("\200\221\187\134\192\201\218\183\142\215\128\144\236\214\131\141\140\247\222\132\143\137\250\213", "\179\186\191\195\231"));
local v166 = v157:CreateGroup(v7("\218\62\11\236\185\28\23\232\245\58\27\240\240\48\22", "\132\153\95\120"), v7("\163\176\22\44\228\201\165\165\187\10\119\184\149\241\225\229\93\121\174\141\245\231\235\92", "\192\209\210\110\77\151\186"));
local v167 = v158:CreateGroup(v7("\194\2\54\253\243\193\160\69\98\196\254\215\244\6\48\240", "\164\128\99\66\137\159"), v7("\18\139\241\191\19\154\236\170\9\141\179\241\79\216\185\233\80\208\190\230\89\221\185\233", "\222\96\233\137"));
local v168 = v158:CreateGroup(v7("\146\186\164\20\200\222\241\170\167\162\13\145", "\144\217\211\199\127\232\147"), v7("\234\45\38\41\198\86\7\80\241\43\100\103\154\20\82\19\168\118\105\112\140\17\82\19", "\36\152\79\94\72\181\37\98"));
local v169 = v158:CreateGroup(v7("\224\221\70\43\223\221\85\127\228\205\74\50\216\214\66\45", "\95\183\184\39"), v7("\167\61\255\39\71\147\7\161\54\227\124\27\207\83\229\104\183\127\3\216\91\225\111\176", "\98\213\95\135\70\52\224"));
local v170 = v159:CreateGroup(v7("\213\170\202\124\93\240\164\137\68\64\231\175\204\100", "\52\158\195\169\23"), v7("\104\190\42\117\149\38\126\159\115\184\104\59\201\100\43\220\41\232\107\33\212\97\44\210", "\235\26\220\82\20\230\85\27"));
local v171 = v159:CreateGroup(v7("\191\164\224\197\124\156\225\175\130\71\152\164\236\198", "\20\232\193\137\162"), v7("\48\221\221\167\244\159\18\101\43\219\159\233\168\221\71\38\113\139\156\243\181\216\64\40", "\17\66\191\165\198\135\236\119"));
local v172 = v159:CreateGroup(v7("\60\170\162\31\191\174\172\247\14\185\161\1\246\252\233", "\177\111\207\206\115\159\136\140"), v7("\23\139\8\21\199\92\90\17\128\20\78\155\0\14\85\222\67\64\141\26\13\81\222\73", "\63\101\233\112\116\180\47"));
local v173 = v160:CreateGroup(v7("\240\62\255\4\253\36\131\17\226\27\246\51\209", "\86\163\91\141\114\152"), v7("\65\9\108\114\41\64\14\96\122\62\9\68\59\34\106\4\88\32\42\111\3\91\38\35", "\90\51\107\20\19"));
local v174 = v160:CreateGroup(v7("\169\249\150\236\50\159\244\197\216\56\143\248\138\224\54", "\93\237\144\229\143"), v7("\7\244\232\24\24\85\16\226\249\29\81\9\90\167\160\78\88\18\76\163\160\73\89\22", "\38\117\150\144\121\107"));
local v175 = v160:CreateGroup(v7("\27\178\253\47\44\183\253\122\107\251\222\63\63\189\225\40\32\186\224\57\40", "\90\77\219\142"), v7("\244\6\57\56\95\20\127\242\13\37\99\3\72\43\182\83\114\109\21\82\42\182\86\113", "\26\134\100\65\89\44\103"));
local v176 = v161:AddDropdown(v7("\215\234\60\55\161\227\193\34\34\173\255\241\63\55", "\196\145\131\80\67"), {[v7("\42\181\30\28", "\136\126\208\102\104\120")]=v7("\94\131\194\87\170\64\125\115\106\139\199\77\189\93\41", "\49\24\234\174\35\207\50\93"),[v7("\58\243\241\157\116\31", "\17\108\146\157\232")]=v96.BrainrotOptions,[v7("\111\198\18\236\58\164\95", "\200\43\163\116\141\79")]=v11.TBrainrot,[v7("\146\35\49\151\185", "\131\223\86\93\227\208\148")]=true,[v7("\208\64\183\164\30\189\226\71\186\179", "\213\131\37\214\214\125")]=true,[v7("\5\42\41\179\227\39\40\46", "\129\70\75\69\223")]=function(v293)
	local v294 = {};
	for v573, v574 in pairs(v293) do
		if v574 then
			table.insert(v294, v573);
		end
	end
	v11.TBrainrot = v294;
	v90();
end});
local v177 = v161:AddDropdown(v7("\96\194\255\253\121\253\107\222\231\232\104\230\73\197", "\143\38\171\147\137\28"), {[v7("\228\135\161\231", "\180\176\226\217\147\99\131")]=v7("\245\176\35\19\214\171\111\42\198\173\46\19\218\182\33", "\103\179\217\79"),[v7("\124\182\16\192\68\159", "\195\42\215\124\181\33\236")]=v96.MutationOptions,[v7("\41\92\49\63\48\244\25", "\152\109\57\87\94\69")]=v11.TMutation,[v7("\212\194\6\183\183", "\200\153\183\106\195\222\178\52")]=true,[v7("\1\230\137\47\74\82\51\225\132\56", "\58\82\131\232\93\41")]=true,[v7("\160\86\220\25\95\62\128\92", "\95\227\55\176\117\61")]=function(v296)
	local v297 = {};
	for v575, v576 in pairs(v296) do
		if v576 then
			table.insert(v297, v575);
		end
	end
	v11.TMutation = v297;
	v90();
end});
v161:CreateDropdown(v7("\53\119\45\66\172\25\115\38\11\138\27\125\54\89\170\27\103", "\203\120\30\67\43"), {v7("\211\36\73", "\185\145\69\45\143"),v7("\167\22\29", "\188\234\127\121\198"),v7("\31\61\28\135", "\227\88\82\115"),v7("\100\13\191\166\22", "\19\35\127\218\199\98"),v7("\57\227\9\231\16\247\15\236\8", "\130\124\155\106"),v7("\229\206\228\169\166\245\104", "\223\181\171\150\207\195\150\28"),v7("\111\53\240\163\0\79", "\105\44\90\131\206")}, v11.TargetMinigameAccuracy, function(v299)
	local v300 = 1217 - (553 + 664);
	while true do
		if ((0 + 0) == v300) then
			v11.TargetMinigameAccuracy = ((type(v299) == v7("\235\225\176\181\13", "\94\159\128\210\217\104")) and v299[79 - (73 + 5)]) or tostring(v299);
			v90();
			break;
		end
	end
end);
v161:CreateDropdown(v7("\96\246\17\186\77\63\202\121\81\245\3\255\114\112\253\127", "\26\48\153\102\223\63\31\153"), {v7("\44\79\255\254\3\76", "\147\98\32\141"),v7("\53\74\224\216\9", "\43\120\35\131\170\102\54"),v7("\122\7\137\185", "\228\52\102\231\214\197\208")}, v11.KickPowerMode, function(v301)
	v11.KickPowerMode = ((type(v301) == v7("\10\225\119\198\239", "\182\126\128\21\170\138\235\121")) and v301[1]) or tostring(v301);
	v90();
end);
v161:CreateSlider(v7("\184\223\33\166\173\26\51\13\203\234\58\241\131\1", "\102\235\186\85\134\230\115\80"), 0 - 0, 100, v11.CustomKickPowerPercent, function(v303)
	v11.CustomKickPowerPercent = v303;
	if v114 then
		v114.Percent = v303 / (283 - 183);
	end
	v90();
end);
local v178 = v161:CreateStatus(v7("\103\30\59\91\123\215\54\94\3\48\31\90\225\6", "\66\55\108\94\63\18\180"), {{[v7("\32\132\145\59\34", "\57\116\237\229\87\71")]=v7("\136\163\236\238\121\252\72\190", "\39\202\209\141\135\23\142"),[v7("\201\50\5\31\55", "\152\159\83\105\106\82")]=v7("\204\139", "\60\225\166\49\146\169")},{[v7("\27\23\59\38\4", "\103\79\126\79\74\97")]=v7("\136\126\193\122\74\3", "\122\218\31\179\19\62"),[v7("\133\215\193\212\204", "\37\211\182\173\161\169\193")]=v7("\186\119", "\217\151\90\45\185\72\27")},{[v7("\247\117\243\30\83", "\54\163\28\135\114")]=v7("\5\206\73\131\90\118\39\213", "\31\72\187\61\226\46"),[v7("\245\7\79\199\66", "\68\163\102\35\178\39\30")]=v7("\243\61", "\113\222\16\186\167\99\213\227")},{[v7("\26\7\239\250\43", "\150\78\110\155")]=v7("\166\245\20\161\146\31\179\85\128", "\32\229\165\71\129\196\126\223"),[v7("\245\136\200\148\132", "\181\163\233\164\225\225")]=v7("\29\198", "\23\48\235\94")}});
v161:CreateToggle(v7("\76\200\221\89\94\48\198\117\213\214", "\178\28\186\184\61\55\83"), v11.APredict, v7("\244\223\66\56\251\13\225\132\212\72\41\224\78\251\193\213\83\124\224\1\249\200\222", "\149\164\173\39\92\146\110"), function(v305)
	local v306 = 0 + 0;
	local v307;
	while true do
		if (v306 == 0) then
			v307 = 0 + 0;
			while true do
				if (v307 == (1 + 0)) then
					if (v178 and v178.SetVisible) then
						v178:SetVisible(v305);
					end
					break;
				end
				if (v307 == (0 - 0)) then
					v11.APredict = v305;
					v90();
					v307 = 1;
				end
			end
			break;
		end
	end
end);
v161:CreateToggle(v7("\210\50\4\16\90\48\250\36\27", "\123\147\71\112\127\122"), v11.AFarm, v7("\237\216\150\126\75\205\217\135\49\68\192\194\129\122\85\140\198\139\114\77\140\203\131\99\75", "\38\172\173\226\17"), function(v308)
	local v309 = 0 + 0;
	while true do
		if (v309 == 1) then
			if (not v11.AFarm and v107.Character and v107.Character:FindFirstChild(v7("\101\4\33\238\67\30\37\235", "\143\45\113\76"))) then
				v107.Character.Humanoid.MaxSlopeAngle = 24 + 21;
			end
			break;
		end
		if (v309 == 0) then
			v11.AFarm = v308;
			v90();
			v309 = 772 - (294 + 477);
		end
	end
end);
v162:CreateToggle(v7("\153\173\8\51\248\140\14\61\177\182\92\119\248\155\19\48\180\189\31\40\248\155\29\47\176", "\92\216\216\124"), v11.ATrainCollect, v7("\122\39\184\79\189\79\32\173\73\243\27\37\169\73\250\83\38\236\65\243\95\114\175\76\252\82\63\236\67\242\82\60\191", "\157\59\82\204\32"), function(v310)
	v11.ATrainCollect = v310;
	if v310 then
		local v677 = 0 + 0;
		local v678;
		while true do
			if (v677 == 1) then
				if v678 then
					v11.TrainAnchorCFrame = v678.CFrame;
				end
				break;
			end
			if (v677 == 0) then
				v11.NextFlashCollect = 0 - 0;
				v678 = v107.Character and v107.Character:FindFirstChild(v7("\16\43\238\251\231\229\218\181\10\49\236\238\217\235\193\165", "\209\88\94\131\154\137\138\179"));
				v677 = 1 - 0;
			end
		end
	else
		v11.TrainAnchorCFrame = nil;
	end
	v90();
end);
v162:CreateSlider(v7("\11\160\215\116\94\0\62\46\36\164\199\104\94\107\21\39\36\160\221\53", "\66\72\193\164\28\126\67\81"), 1, 60, v11.TrainCollectDelay, function(v312)
	v11.TrainCollectDelay = v312;
	v11.NextFlashCollect = tick() + (v11.TrainCollectDelay * (16 + 44));
	v90();
end);
v11.PlotProtectedList = {v7("\201\35\166\93", "\22\135\76\200\56\70")};
local v180 = v163:AddDropdown(v7("\189\34\247\48\88\226\153\20\234\43\77\229\130\39\246\13\121", "\129\237\80\152\68\61"), {[v7("\101\173\28\231", "\56\49\200\100\147\124\119")]=v7("\252\44\176\228\201\61\171\245\200\126\157\226\205\55\177\226\195\42\172", "\144\172\94\223"),[v7("\18\14\174\82\33\28", "\39\68\111\194")]=v11.PlotProtectedList,[v7("\242\163\225\198\108\187\194", "\215\182\198\135\167\25")]=(v11.TProtectedBrainrots or {}),[v7("\160\92\230\92\132", "\40\237\41\138")]=true,[v7("\244\113\251\234\73\207\117\248\244\79", "\42\167\20\154\152")]=true,[v7("\105\255\174\78\115\32\73\245", "\65\42\158\194\34\17")]=function(v315)
	local v316 = 0 + 0;
	local v317;
	while true do
		if (v316 == (0 - 0)) then
			v317 = {};
			for v835, v836 in pairs(v315) do
				if v836 then
					table.insert(v317, v835);
				end
			end
			v316 = 983 - (97 + 885);
		end
		if ((1 + 0) == v316) then
			v11.TProtectedBrainrots = v317;
			v90();
			break;
		end
	end
end});
v180.Refresh = function(v318, v319)
	v318:SetValues(v319);
end;
task.spawn(function()
	while v11.HubRunning do
		task.wait(5);
		local v577 = v119();
		local v578 = {};
		if (v577 and v577:FindFirstChild(v7("\41\43\93\24\62", "\142\122\71\50\108\77\141\123"))) then
			for v837, v838 in ipairs(v577.Slots:GetChildren()) do
				local v839 = 0 - 0;
				local v840;
				while true do
					if (v839 == (365 - (271 + 94))) then
						v840 = v838:FindFirstChild(v7("\37\174\254\27\62\17\146\254\10\47", "\91\117\194\159\120"));
						if (v840 and v840:GetAttribute(v7("\51\57", "\68\122\125\94\120\85\145"))) then
							local v1130 = v840:GetAttribute(v7("\62\56", "\218\119\124\175\62\168\185"));
							local v1131 = v840:GetAttribute(v7("\136\229\92\197\177\249\71\202", "\164\197\144\40")) or v7("\173\255\164\142", "\214\227\144\202\235\189");
							local v1132 = v840:GetAttribute(v7("\193\160\145\126\28", "\92\141\197\231\27\112\211\51")) or (1604 - (777 + 826));
							local v1133 = string.format(v7("\221\211\156\237\148\245\194\202\230\194\166\196\207\176\236", "\177\134\159\234\195"), tostring(v1132), v1130, v1131);
							table.insert(v578, v1133);
						end
						break;
					end
				end
			end
		end
		if (#v578 == 0) then
			table.insert(v578, v7("\147\228\49\165", "\169\221\139\95\192"));
		end
		v11.PlotProtectedList = v578;
		pcall(function()
			if (v180 and v180.Refresh) then
				v180:Refresh(v11.PlotProtectedList);
			end
		end);
	end
end);
v163:CreateToggle(v7("\251\133\126\61\46\35\158\187\109\48\54\35\221\159\118\48\44", "\70\190\235\31\95\66"), v11.AProtectFilter, v7("\138\240\21\242\224\185\246\90\235\228\174\225\18\239\235\189\162\28\239\233\174\231\8\166\230\181\236\28\239\226\175\240\27\242\236\181\236\9", "\133\218\130\122\134"), function(v320)
	local v321 = 0;
	while true do
		if (v321 == (0 + 0)) then
			v11.AProtectFilter = v320;
			v90();
			break;
		end
	end
end);
v163:CreateToggle(v7("\29\234\247\203\156\147\52\61\252\230\132\254\177\57\53\241\241\203\200", "\88\92\159\131\164\188\195"), v11.APlaceBest, v7("\161\59\171\68\151\251\209\129\45\186\11\213\238\206\148\110\175\78\195\248\157\137\32\255\91\219\228\201", "\189\224\78\223\43\183\139"), function(v322)
	v11.APlaceBest = v322;
	v90();
end);
v11.TUpgradeBase = {};
local v183 = v164:AddDropdown(v7("\27\236\141\4\192\42\249\174\4\206\62\248\133\1\207\7\216", "\161\78\156\234\118"), {[v7("\147\178\209\200", "\188\199\215\169")]=v7("\218\0\83\111\237\238\73\125\105\233\245\7\77\116\252", "\136\156\105\63\27"),[v7("\45\141\117\33\30\159", "\84\123\236\25")]=v11.PlotBrainrotList,[v7("\212\142\172\22\185\185\228", "\213\144\235\202\119\204")]=(v11.TUpgrade or {v7("\2\22\199", "\45\67\120\190\74\72\67")}),[v7("\13\55\225\177\240", "\137\64\66\141\197\153\232\142")]=true,[v7("\48\213\35\180\139\11\209\32\170\141", "\232\99\176\66\198")]=true,[v7("\207\32\36\10\121\140\250\39", "\76\140\65\72\102\27\237\153")]=function(v324)
	local v325 = 0;
	local v326;
	while true do
		if (v325 == 1) then
			v11.TUpgrade = v326;
			v11.TUpgradeBase = {};
			v325 = 1717 - (686 + 1029);
		end
		if (v325 == (1358 - (1074 + 282))) then
			for v841, v842 in ipairs(v326) do
				local v843 = 1617 - (1359 + 258);
				local v844;
				while true do
					if (v843 == (0 - 0)) then
						v844 = string.gsub(v842, v7("\116\159\45\254\193\68\240\15\222\93\151\234\68\173\0", "\222\42\186\118\178\183\97"), "");
						if not table.find(v11.TUpgradeBase, v844) then
							table.insert(v11.TUpgradeBase, v844);
						end
						break;
					end
				end
			end
			v90();
			break;
		end
		if (v325 == 0) then
			v326 = {};
			for v845, v846 in pairs(v324) do
				if v846 then
					table.insert(v326, v845);
				end
			end
			v325 = 1936 - (1730 + 205);
		end
	end
end});
v183.Refresh = function(v327, v328)
	v327:SetValues(v328);
end;
task.spawn(function()
	while v11.HubRunning do
		local v580 = 0;
		local v581;
		while true do
			if ((529 - (67 + 461)) == v580) then
				if (v581 and v581:FindFirstChild(v7("\110\224\75\158\78", "\234\61\140\36"))) then
					local v973 = {v7("\0\211\163", "\111\65\189\218\18")};
					for v1031, v1032 in ipairs(v581.Slots:GetChildren()) do
						local v1033 = v1032:FindFirstChild(v7("\115\71\26\54\14\88\159\66\89\15", "\207\35\43\123\85\107\60"));
						if v1033 then
							for v1156, v1157 in ipairs(v1033:GetChildren()) do
								if (v1157:IsA(v7("\93\165\164\239\117", "\25\16\202\192\138")) and not v1157.Name:match(v7("\213\194\185\224\166\236", "\148\157\171\205\130\201"))) then
									local v1236 = 0;
									local v1237;
									local v1238;
									local v1239;
									while true do
										if (v1236 == 0) then
											v1237 = v120(v1157);
											v1238 = v1157:GetAttribute(v7("\15\209\98\44\221", "\150\67\180\20\73\177")) or v1033:GetAttribute(v7("\161\29\12\72\129", "\45\237\120\122")) or 1;
											v1236 = 1;
										end
										if (v1236 == (1 - 0)) then
											v1239 = string.format(v7("\236\196\180\98\146\251\159\108\146\251\226\23\146\251\159", "\76\183\136\194"), tostring(v1238), v1157.Name, v1237);
											table.insert(v973, v1239);
											break;
										end
									end
								end
							end
						end
					end
					v11.PlotBrainrotList = v973;
					pcall(function()
						if (v183 and v183.Refresh) then
							v183:Refresh(v973);
						end
					end);
				end
				break;
			end
			if ((0 - 0) == v580) then
				task.wait(1 + 4);
				v581 = v119();
				v580 = 630 - (129 + 500);
			end
		end
	end
end);
v164:CreateSlider(v7("\87\231\253\120\124\74\2\127\234", "\116\26\134\133\88\48\47"), 1712 - (1157 + 554), 107 - 32, v11.MaxUpLevel, function(v329)
	local v330 = 607 - (82 + 525);
	while true do
		if (v330 == (0 + 0)) then
			v11.MaxUpLevel = v329;
			v90();
			break;
		end
	end
end);
v164:CreateSlider(v7("\43\209\167\246\188\118\27\129\132\225\177\115\7", "\18\126\161\192\132\221"), 2 - 1, 1653 - (948 + 675), v11.AutoUpgradeDelay, function(v331)
	v11.AutoUpgradeDelay = v331;
	v90();
end);
v164:CreateToggle(v7("\126\61\186\11\22\106\56\169\22\87\91\45\238\38\68\94\33\160\22\89\75", "\54\63\72\206\100"), v11.AAutoUpgrade, v7("\233\76\81\117\165\110\216\94\87\123\225\126\219\25\86\118\234\111\136\73\64\110\246\59\193\87\5\106\233\116\220", "\27\168\57\37\26\133"), function(v333)
	v11.AAutoUpgrade = v333;
	v90();
end);
v164:CreateToggle(v7("\12\191\104\167\151\24\186\123\186\214\41\175\60\152\219\34\190", "\183\77\202\28\200"), v11.APlotUpgrade, v7("\54\38\157\7\26\50\157\1\20\50\133\4\14\115\156\24\16\33\136\12\18\115\153\4\24\39\201\27\27\60\157\27", "\104\119\83\233"), function(v335)
	v11.APlotUpgrade = v335;
	v90();
end);
v165:CreateToggle(v7("\212\237\51\45\3\193\234\38\43\77", "\35\149\152\71\66"), v11.ATrain, v7("\45\250\67\185\52\89\255\71\185\61\17\252\2\177\47\13\231\79\177\46\16\235\67\188\54\0", "\90\121\136\34\208"), function(v337)
	local v338 = 0;
	while true do
		if (v338 == 0) then
			v11.ATrain = v337;
			v90();
			break;
		end
	end
end);
v165:CreateToggle(v7("\230\27\65\17\135\45\89\31\206\3\21\76\223", "\126\167\110\53"), v11.A2xTrain, v7("\28\5\58\247\156\60\49\25\45\243\156\109\37\80\44\247\210\42\46\80\60\253\203\62\47\20\61", "\95\93\112\78\152\188"), function(v339)
	local v340 = 0;
	while true do
		if (v340 == 0) then
			v11.A2xTrain = v339;
			v90();
			break;
		end
	end
end);
v165:CreateToggle(v7("\224\224\145\26\164\140\215\195\252\151\1\236", "\178\161\149\229\117\132\222"), v11.ARebirth, v7("\169\206\201\163\225\4\163\33\129\201\201\164\225\1\174\38\134\155\208\173\185\86\176\34\132\206\216\236\172\19\178", "\67\232\187\189\204\193\118\198"), function(v341)
	local v342 = 0 + 0;
	while true do
		if (v342 == (0 + 0)) then
			v11.ARebirth = v341;
			v90();
			break;
		end
	end
end);
v166:CreateSlider(v7("\168\33\185\44\62\1\251\203\10\176\44\58\27", "\143\235\78\213\64\91\98"), 2 - 1, 1453 - (406 + 447), v11.CollectDelay, function(v343)
	v11.CollectDelay = v343;
	v90();
end);
v166:CreateToggle(v7("\172\93\144\230\48\149\130\68\136\236\115\162\205\107\133\250\120", "\214\237\40\228\137\16"), v11.ACollect, v7("\164\246\251\214\67\165\138\239\227\220\0\178\197\224\224\208\13\181\197\234\225\153\19\170\138\247\175\223\15\169\138\241\252", "\198\229\131\143\185\99"), function(v345)
	local v346 = 117 - (91 + 26);
	while true do
		if (v346 == 0) then
			v11.ACollect = v345;
			v90();
			break;
		end
	end
end);
v167:CreateDropdown(v7("\115\141\188\103\93\137\232\65\94\153\166\119\66", "\19\49\236\200"), {"1","2","3","4","5","6","7","8","9",v7("\175\103", "\218\158\87\150\215\132")}, v11.BattleRounds, function(v347)
	local v348 = 0;
	while true do
		if (v348 == (265 - (260 + 5))) then
			if (type(v347) == v7("\239\31\219\238\51", "\173\155\126\185\130\86\66")) then
				v11.BattleRounds = v347[2 - 1] or "3";
			else
				v11.BattleRounds = tostring(v347);
			end
			v90();
			break;
		end
	end
end);
v167:CreateToggle(v7("\192\168\187\197\132\233\165\129\187\202\141\252\228\181\169", "\140\133\198\218\167\232"), v11.BattleGamepass, v7("\128\61\177\61\128\186\59\182\113\129\245\60\177\106\133\167\42\167\61\148\180\61\167\61\133\160\58\187\112\133\161\39\183\124\136\185\55", "\228\213\78\212\29"), function(v349)
	v11.BattleGamepass = v349;
	v90();
end);
v167:CreateSlider(v7("\170\69\184\69\219\139\77\175\0\249\148\12\162\10\171\180\88\183\23\255", "\139\231\44\214\101"), 821 - (265 + 554), 1576 - (1440 + 131), v11.BattleMinPlayers, function(v351)
	v11.BattleMinPlayers = v351;
end);
v167:CreateToggle(v7("\248\250\18\81\80\147\48\2\205\227\3\30\60\190\51\20\192", "\118\185\143\102\62\112\209\81"), v11.AAutoBattle, v7("\125\101\61\233\168\20\8\61\28\114\40\242\177\25\25\120\78\117\56\243\160\6\8\43\28\113\39\226\229\20\31\59\89\96\61\245", "\88\60\16\73\134\197\117\124"), function(v353)
	v11.AAutoBattle = v353;
	v90();
end);
v167:CreateToggle(v7("\113\255\236\199\1\113\233\251\205\81\68\170\218\201\85\68\230\253\136\104\94\252\241\220\68\67", "\33\48\138\152\168"), v11.AAutoAcceptBattle, v7("\83\3\36\94\204\54\102\31\51\80\205\59\107\86\49\82\194\50\98\2\112\92\192\35\113\30\112\93\206\53\112\15\112\67\196\38\103\19\35\69\210", "\87\18\118\80\49\161"), function(v355)
	local v356 = 0 - 0;
	while true do
		if (v356 == 0) then
			v11.AAutoAcceptBattle = v355;
			v90();
			break;
		end
	end
end);
v168:CreateSlider(v7("\103\23\217\171\240\124\17\205\165\162", "\208\44\126\186\192"), 1395 - (253 + 1142), 353 - (133 + 120), v11.MasteryKickPower, function(v357)
	v11.MasteryKickPower = v357;
end);
v168:CreateDropdown(v7("\197\31\183\195\0\188\228\75\227\18\171\194", "\46\151\122\196\166\116\156\169"), {v7("\193\228\67\30", "\155\133\141\38\122"),v7("\17\26", "\197\69\74\204\33\47\31")}, v11.MasteryResetMethod, function(v359)
	if (type(v359) == v7("\228\78\88\139\245", "\231\144\47\58")) then
		v11.MasteryResetMethod = v359[498 - (178 + 319)] or v7("\150\209\223\113", "\89\210\184\186\21\120\93\175");
	else
		v11.MasteryResetMethod = tostring(v359);
	end
end);
v168:CreateToggle(v7("\144\70\104\218\57\28\176\65\113\149\84\59\162\71\121\199\96", "\90\209\51\28\181\25"), v11.AAutoMastery, v7("\241\110\67\225\178\209\111\82\174\178\209\104\67\235\173\201\59\91\235\169\213\119\68\174\185\209\105\90\231\177\215", "\223\176\27\55\142"), function(v360)
	v11.AAutoMastery = v360;
end);
local v185 = {v7("\10\180\192\176", "\213\68\219\174")};
pcall(function()
	local v362 = require(game:GetService(v7("\57\229\51\235\35\198\62\107\14\228\16\243\37\215\62\120\14", "\31\107\128\67\135\74\165\95")).Shared.Data.SacrificeData);
	if (v362 and v362.Recipes) then
		for v738, v739 in pairs(v362.Recipes) do
			table.insert(v185, v738);
		end
	end
end);
v169:CreateDropdown(v7("\236\233\238\74\68\165\152\223\249\76\85\185\221\250", "\209\184\136\156\45\33"), v185, v11.TTargetWeatherEvent, function(v363)
	v11.TTargetWeatherEvent = v363;
end);
v169:CreateToggle(v7("\38\221\97\7\248\52\221\120\5\183\9\136\66\13\185\19\192\112\26", "\216\103\168\21\104"), v11.AAutoSummonWeather, v7("\75\184\78\169\119\163\80\228\108\172\81\163\125\185\3\179\125\172\87\172\125\191\3\161\110\168\77\176\56\169\74\182\125\174\87\168\97", "\196\24\205\35"), function(v365)
	v11.AAutoSummonWeather = v365;
end);
local v186 = {v7("\10\142\229\7\59\135\247", "\102\78\235\131")};
pcall(function()
	local v367 = 0;
	local v368;
	while true do
		if (0 == v367) then
			v368 = game:GetService(v7("\200\43\36\72\78\58\182\32\255\42\7\80\72\43\182\51\255", "\84\154\78\84\36\39\89\215")).Shared.Data.KickStylesData;
			for v847, v848 in ipairs(v368:GetChildren()) do
				if (v848:IsA(v7("\208\238\82\77\9\248\210\85\74\12\237\245", "\101\157\129\54\56")) and (v848.Name ~= v7("\57\172\140\170\54\117\9", "\25\125\201\234\203\67"))) then
					table.insert(v186, v848.Name);
				end
			end
			break;
		end
	end
end);
v170:CreateDropdown(v7("\77\245\10\4\17\51\83\82\253\27\8\84\20\7\96\248\29", "\115\25\148\120\99\116\71"), v186, v11.TargetKickStyle, function(v369)
	if (type(v369) == v7("\24\60\187\40\68", "\33\108\93\217\68")) then
		v11.TargetKickStyle = v369[1 + 0] or v7("\255\78\167\172\206\71\181", "\205\187\43\193");
	else
		v11.TargetKickStyle = tostring(v369);
	end
	v90();
end);
v170:CreateToggle(v7("\223\103\17\208\190\80\16\198\190\52\69\250\239\103\12\207\190\65\17\198\242\119", "\191\158\18\101"), v11.AAutoKickStyle, v7("\245\214\149\180\167\196\208\130\247\174\203\199\199\178\190\208\202\151\247\164\204\192\140\247\188\209\218\139\178\239\196\214\147\184\162\196\215\142\180\174\201\207\158", "\207\165\163\231\215"), function(v370)
	v11.AAutoKickStyle = v370;
	v90();
end);
v11.WeightList = {v7("\232\246\247\83", "\16\166\153\153\54\68")};
if v135 then
	for v684, v685 in ipairs(v135:GetChildren()) do
		table.insert(v11.WeightList, v685.Name);
	end
end
v171:CreateDropdown(v7("\230\178\210\65\49\53\185\229\182\201\65\60\53", "\153\178\211\160\38\84\65"), v11.WeightList, v11.TTargetWeight, function(v372)
	v11.TTargetWeight = v372;
end);
v171:CreateToggle(v7("\163\30\78\36\194\41\79\50\194\56\95\39\135\8\78\46\134\75\109\46\139\12\82\63", "\75\226\107\58"), v11.ABuyWeights, v7("\121\203\5\117\81\210\216\74\221\25\123\2\199\141\75\219\29\127\18\214\200\92\158\6\127\24\197\197\76\158\2\110\8\206\200", "\173\56\190\113\26\113\162"), function(v374)
	local v375 = 1542 - (1221 + 321);
	while true do
		if (v375 == (0 - 0)) then
			v11.ABuyWeights = v374;
			v90();
			break;
		end
	end
end);
v171:CreateToggle(v7("\234\203\57\10\183\233\203\52\69\213\206\205\57\69\192\206\215\42\13\227", "\151\171\190\77\101"), v11.ABuyBest, v7("\240\33\244\166\251\118\75\196\33\252\233\232\104\25\198\39\249\186\253\61\9\192\60\236\233\239\120\2\194\39\236\233\241\115\75\194\46\245\172", "\107\165\79\152\201\152\29"), function(v376)
	v11.ABuyBest = v376;
	v90();
end);
v171:CreateToggle(v7("\118\91\252\196\20\93\66\87\168\248\68\122\82\74", "\31\55\46\136\171\52"), v11.ABuySpeed, v7("\240\61\200\251\220\41\200\253\210\41\208\248\200\104\201\228\214\58\221\240\212\59\156\255\216\43\215\180\194\56\217\241\213", "\148\177\72\188"), function(v378)
	local v379 = 0 + 0;
	while true do
		if (v379 == (0 - 0)) then
			v11.ABuySpeed = v378;
			v90();
			break;
		end
	end
end);
v172:AddDropdown(v7("\128\183\65\220\180\191\67\214\132\164\86\218\168\164\88\199", "\179\198\214\55"), {[v7("\196\9\106\98", "\179\144\108\18\22\37")]=v7("\224\162\13\134\221\207\183\30\201\237\212\162\18\135\221\201\183", "\175\166\195\123\233"),[v7("\217\195\81\92\245\252", "\144\143\162\61\41")]=v96.BrainrotOptions,[v7("\196\214\27\81\103\139\39", "\83\128\179\125\48\18\231")]=v11.TSSellBrainrot,[v7("\112\162\255\201\78", "\126\61\215\147\189\39")]=true,[v7("\75\250\28\87\123\247\28\71\116\250", "\37\24\159\125")]=true,[v7("\249\167\121\78\216\167\118\73", "\34\186\198\21")]=function(v380)
	local v381 = {};
	for v582, v583 in pairs(v380) do
		if v583 then
			table.insert(v381, v582);
		end
	end
	v11.TSSellBrainrot = v381;
	v90();
	if v11.TriggerFavScan then
		task.spawn(v11.TriggerFavScan);
	end
end});
v172:AddDropdown(v7("\222\9\211\82\208\241\28\192\111\195\234\1\209\68", "\162\152\104\165\61"), {[v7("\249\42\170\105", "\133\173\79\210\29\16")]=v7("\171\125\251\36\159\117\249\46\205\78\236\57\132\104\244", "\75\237\28\141"),[v7("\234\94\192\164\42\8", "\129\188\63\172\209\79\123\135")]=v96.RarityOptions,[v7("\100\225\224\204\85\232\242", "\173\32\132\134")]=v11.TSSellRarity,[v7("\99\14\4\251\167", "\173\46\123\104\143\206\81")]=true,[v7("\135\24\35\152\70\139\0\182\17\39", "\97\212\125\66\234\37\227")]=true,[v7("\169\226\186\57\28\139\224\189", "\126\234\131\214\85")]=function(v383)
	local v384 = 0 - 0;
	local v385;
	while true do
		if (v384 == (0 + 0)) then
			v385 = {};
			for v849, v850 in pairs(v383) do
				if v850 then
					table.insert(v385, v849);
				end
			end
			v384 = 1 + 0;
		end
		if (v384 == (1 - 0)) then
			v11.TSSellRarity = v385;
			v90();
			v384 = 409 - (204 + 203);
		end
		if (v384 == 2) then
			if v11.TriggerFavScan then
				task.spawn(v11.TriggerFavScan);
			end
			break;
		end
	end
end});
v172:AddDropdown(v7("\162\212\95\85\93\141\193\76\119\90\144\212\93\83\64\138", "\47\228\181\41\58"), {[v7("\146\249\193\47", "\127\198\156\185\91\99\80")]=v7("\211\27\218\255\181\2\45\219\181\55\217\228\166\31\48\209\251", "\190\149\122\172\144\199\107\89"),[v7("\4\4\253\235\251\33", "\158\82\101\145\158")]=v96.MutationOptions,[v7("\84\251\4\23\81\124\234", "\36\16\158\98\118")]=v11.TSSellMutation,[v7("\237\3\207\239\81", "\133\160\118\163\155\56\136\71")]=true,[v7("\197\167\112\224\181\23\180\244\174\116", "\213\150\194\17\146\214\127")]=true,[v7("\56\168\168\216\68\165\161\61", "\86\123\201\196\180\38\196\194")]=function(v386)
	local v387 = 0;
	local v388;
	while true do
		if (v387 == (78 - (48 + 30))) then
			v388 = {};
			for v851, v852 in pairs(v386) do
				if v852 then
					table.insert(v388, v851);
				end
			end
			v387 = 1;
		end
		if (v387 == (1 + 1)) then
			if v11.TriggerFavScan then
				task.spawn(v11.TriggerFavScan);
			end
			break;
		end
		if (v387 == (1965 - (1472 + 492))) then
			v11.TSSellMutation = v388;
			v90();
			v387 = 5 - 3;
		end
	end
end});
v172:CreateToggle(v7("\214\253\205\160\183\206\216\185\248\250\208\187\242\168\255\166\251\252\220\189", "\207\151\136\185"), v11.AAutoFav, v7("\138\154\56\131\103\107\116\187\195\27\135\120\116\49\137\143\36\194\123\118\49\187\134\36\135\119\108\116\172\195\46\139\120\108\116\186\195\59\135\96\108\120\166\132\59", "\17\200\227\72\226\20\24"), function(v389)
	local v390 = 0 + 0;
	local v391;
	while true do
		if (v390 == (611 - (258 + 353))) then
			v391 = 1994 - (1382 + 612);
			while true do
				if (v391 == (1 + 0)) then
					if (v389 and v11.TriggerFavScan) then
						v11.TriggerFavScan();
					end
					break;
				end
				if (v391 == (0 + 0)) then
					v11.AAutoFav = v389;
					v90();
					v391 = 1 + 0;
				end
			end
			break;
		end
	end
end);
v172:CreateButton(v7("\131\68\23\219\137\208\227\243\240\99\9\214\192\255\253\240\164\82", "\159\208\33\123\183\169\145\143"), function()
	local v392 = 0 - 0;
	while true do
		if (v392 == (0 + 0)) then
			if (v11.AAutoFav and v11.TriggerFavScan) then
				v11.TriggerFavScan();
				task.wait(1);
			end
			if v128 then
				local v923 = 0;
				while true do
					if (v923 == (119 - (35 + 84))) then
						pcall(function()
							v128:InvokeServer();
						end);
						v95:Notify({[v7("\198\83\44\58\247", "\86\146\58\88")]=v7("\107\218\230\204\238\200\58\246", "\154\56\191\138\160\206\137\86"),[v7("\165\86\251\147\121\52\149", "\172\230\57\149\231\28\90\225")]=v7("\39\178\131\209\61\207\7\174\199\146\9\206\22\165\203\244\41\205\66\185\159\220\43\222\6\234\132\215\46\212\16\175\198\193\45\215\14\163\136\213\102", "\187\98\202\230\178\72"),[v7("\5\244\182\49\94\40\238\170", "\42\65\129\196\80")]=(218 - (75 + 140))});
						break;
					end
				end
			else
				v95:Notify({[v7("\54\67\73\214\18", "\142\98\42\61\186\119\103\98")]=v7("\29\173\16\7\42", "\104\88\223\98"),[v7("\103\248\236\218\7\227\80", "\141\36\151\130\174\98")]=v7("\183\127\206\1\196\91\206\1\196\104\199\0\139\110\199\77\138\117\214\77\130\117\215\3\128\59", "\109\228\26\162"),[v7("\122\240\239\121\244\239\81\235", "\134\62\133\157\24\128")]=(10 - 7)});
			end
			break;
		end
	end
end);
getgenv().TargetServerInput = "";
v173:CreateInput(v7("\45\170\19\215\111\130\211\21\179\31\203\111\157\223\9\174\90\150\111\155\217\5\140\30", "\182\103\197\122\185\79\209"), v7("\195\134\242\99\5\8\217\136\227\94\4\8\251\130\243\114", "\40\147\231\129\23\96"), nil, function(v393)
	getgenv().TargetServerInput = v393;
end);
v173:CreateButton(v7("\95\247\133\75\251\159\217\103\238\137\87\251\133\210\102\236\141\75\184\169", "\188\21\152\236\37\219\204"), function()
	local v395 = 0;
	local v396;
	while true do
		if (v395 == (1800 - (923 + 876))) then
			task.spawn(function()
				local v853 = nil;
				local v854 = nil;
				if v396:find(v7("\19\30\66\207\147\137", "\224\95\75\26\150\169\181\180")) then
					local v976 = 0 - 0;
					local v977;
					while true do
						if (v976 == (812 - (284 + 528))) then
							v977 = v396:match(v7("\39\239\224\17\30\240\62\48\228\134\21\15\229\40", "\22\107\186\184\72\36\204"));
							if v977 then
								local v1189 = 1019 - (867 + 152);
								local v1190;
								local v1191;
								local v1192;
								while true do
									if (v1189 == 1) then
										v1192 = nil;
										while true do
											if (v1190 == (1106 - (709 + 397))) then
												v1191, v1192 = pcall(v136, v977);
												if (v1191 and v1192 and (v1192 ~= "")) then
													v854 = v1192;
												end
												break;
											end
										end
										break;
									end
									if (v1189 == (0 - 0)) then
										v1190 = 0;
										v1191 = nil;
										v1189 = 37 - (21 + 15);
									end
								end
							end
							break;
						end
					end
				elseif (v396:find(v7("\245\178\38\66\1\255\243\39\65\3", "\110\135\221\68\46")) or v396:find(v7("\243\58\13\232\203\154\63\190", "\91\131\86\108\139\174\211"))) then
					local v1089 = 0;
					local v1090;
					local v1091;
					local v1092;
					while true do
						if (v1089 == 1) then
							v1092 = nil;
							while true do
								if (0 == v1090) then
									local v1324 = 0 - 0;
									while true do
										if (v1324 == 0) then
											v1091 = v396:match(v7("\235\39\185\20\88\210\47\229\95\24\255\96\241", "\61\155\75\216\119"));
											if v1091 then
												v853 = tonumber(v1091);
											end
											v1324 = 1 - 0;
										end
										if ((1 + 0) == v1324) then
											v1090 = 2 - 1;
											break;
										end
									end
								end
								if (v1090 == 1) then
									v1092 = v396:match(v7("\13\165\161\40\89\7\222\1\130\182\97\16\50\227\66\238\161\1\19\64", "\189\100\203\210\92\56\105"));
									if v1092 then
										v854 = v1092;
									end
									break;
								end
							end
							break;
						end
						if (v1089 == (0 - 0)) then
							v1090 = 0 + 0;
							v1091 = nil;
							v1089 = 136 - (97 + 38);
						end
					end
				end
				if not v854 then
					v854 = v396:match(v7("\103\20\229\109\55\20\229\109\55\20\229\109\55\20\229\109\55\20\176\109\55\20\229\109\55\20\229\109\98\20\229\109\55\20\229\109\55\20\176\109\55\20\229\109\55\20\229\109\98\20\229\109\55\20\229\109\55\20\229\109\55\20\229\109\55\20\229\109\55\20\229\109\55\24", "\72\79\49\157")) or v396:match(v7("\192\139\116\171\181\251\116\241\179\245\38\129\195\245\124\135\205\167\12\247\205\253\10\249\159\141\122\249\197\139\116\171\181\251\120", "\220\232\208\81")) or string.gsub(v396, v7("\203\251\246\122\100\20\236\188\251\246\122\104", "\193\149\222\133\80\76\58"), v7("\131\12", "\178\166\61\47"));
				end
				if not v853 then
					v853 = game.PlaceId;
				end
				if (v854 and (v854 ~= "")) then
					v95:Notify({[v7("\207\67\252\118\207", "\94\155\42\136\26\170")]=v7("\172\48\54\165\141\49\33", "\213\228\95\70"),[v7("\9\180\204\144\114\36\175", "\23\74\219\162\228")]=(v7("\13\227\74\170\43\54\244\82\166\53\62\166\82\160\123\9\234\71\172\62\99\166", "\91\89\134\38\207") .. tostring(v853) .. v7("\4\242\136\31\29\195\51\69\224\203\51\73\144", "\71\36\142\168\86\115\176") .. v854),[v7("\251\180\96\190\23\183\89\71", "\41\191\193\18\223\99\222\54")]=3});
					task.wait(80.5 - (52 + 28));
					pcall(function()
						game:GetService(v7("\159\35\203\47\186\164\52\211\25\175\185\48\206\41\175", "\202\203\70\167\74")):TeleportToPlaceInstance(v853, v854, v107);
					end);
				else
					v95:Notify({[v7("\24\8\200\63\116", "\17\76\97\188\83")]=v7("\160\53\203\56\34", "\195\229\71\185\87\80\227\43"),[v7("\195\243\14\68\234\238\232", "\143\128\156\96\48")]=v7("\158\208\249\30\18\188\145\228\29\87\189\201\228\0\22\187\197\176\56\24\186\248\244\83", "\119\216\177\144\114"),[v7("\237\60\235\67\221\32\246\76", "\34\169\73\153")]=(2 + 1)});
				end
			end);
			break;
		end
		if ((849 - (59 + 790)) == v395) then
			local v745 = 0;
			local v746;
			while true do
				if ((0 + 0) == v745) then
					v746 = 0;
					while true do
						if ((1 + 0) == v746) then
							v395 = 941 - (467 + 473);
							break;
						end
						if (v746 == (0 - 0)) then
							v396 = getgenv().TargetServerInput;
							if (not v396 or (v396 == "")) then
								local v1193 = 0 - 0;
								while true do
									if (v1193 == (0 - 0)) then
										v95:Notify({[v7("\116\224\35\0\69", "\108\32\137\87")]=v7("\143\250\18\169\61", "\57\202\136\96\198\79\153\43"),[v7("\136\44\164\179\136\169\236", "\152\203\67\202\199\237\199")]=v7("\211\77\176\26\11\53\112\245\186\70\173\31\11\108\56", "\134\154\35\192\111\127\21\25"),[v7("\156\51\27\11\52\219\183\40", "\178\216\70\105\106\64")]=3});
										return;
									end
								end
							end
							v746 = 1;
						end
					end
					break;
				end
			end
		end
	end
end);
v174:AddDropdown(v7("\157\233\9\131\165\227\0\169\184\237\2\133\184\227\31\175\184\227\27", "\235\202\140\107"), {[v7("\56\113\44\188", "\165\108\20\84\200\137\71\151")]=v7("\77\177\41\128\117\187\32\200\88\166\42\129\116\166\36\156", "\232\26\212\75"),[v7("\1\72\126\253\242\36", "\151\87\41\18\136")]=v96.BrainrotOptions,[v7("\127\170\204\209\235\87\187", "\158\59\207\170\176")]=v11.WBBrainrot,[v7("\98\75\63\93\133", "\236\47\62\83\41")]=true,[v7("\201\172\33\41\169\138\251\171\44\62", "\226\154\201\64\91\202")]=true,[v7("\226\72\17\20\72\189\194\66", "\220\161\41\125\120\42")]=function(v397)
	local v398 = 0;
	local v399;
	while true do
		if (v398 == (0 - 0)) then
			v399 = {};
			for v855, v856 in pairs(v397) do
				if v856 then
					table.insert(v399, v855);
				end
			end
			v398 = 1 + 0;
		end
		if ((2 - 1) == v398) then
			v11.WBBrainrot = v399;
			v90();
			break;
		end
	end
end});
v174:AddDropdown(v7("\139\116\162\6\179\126\171\60\189\99\169\26\165\85\178\1\172", "\110\220\17\192"), {[v7("\64\124\44\14", "\199\20\25\84\122\139\87\145")]=v7("\97\0\209\186\30\248\7\59\220\188\18\254\94", "\138\39\105\189\206\123"),[v7("\41\6\133\56\246\234", "\159\127\103\233\77\147\153\175")]=v96.RarityOptions,[v7("\35\245\226\171\85\199\19", "\171\103\144\132\202\32")]=v11.WBRarity,[v7("\61\58\229\24\25", "\108\112\79\137")]=true,[v7("\12\199\117\58\174\9\232\55\51\199", "\85\95\162\20\72\205\97\137")]=true,[v7("\212\252\38\208\15\249\206\252", "\173\151\157\74\188\109\152")]=function(v400)
	local v401 = 0 - 0;
	local v402;
	while true do
		if (v401 == (0 - 0)) then
			v402 = {};
			for v857, v858 in pairs(v400) do
				if v858 then
					table.insert(v402, v857);
				end
			end
			v401 = 1 + 0;
		end
		if ((1 + 0) == v401) then
			v11.WBRarity = v402;
			v90();
			break;
		end
	end
end});
v174:AddDropdown(v7("\19\13\58\213\211\91\222\222\49\28\57\201\213\91\219\215\54\7\40", "\147\68\104\88\189\188\52\181"), {[v7("\46\141\147\196", "\176\122\232\235")]=v7("\166\124\54\91\235\146\53\23\90\250\129\97\51\64\224", "\142\224\21\90\47"),[v7("\66\213\43\67\161\152", "\229\20\180\71\54\196\235")]=v96.MutationOptions,[v7("\13\123\199\226\224\166\148", "\224\73\30\161\131\149\202")]=v11.WBMutation,[v7("\220\240\253\68\248", "\48\145\133\145")]=true,[v7("\105\73\180\252\210\36\91\78\185\235", "\76\58\44\213\142\177")]=true,[v7("\232\37\30\33\122\202\39\25", "\24\171\68\114\77")]=function(v403)
	local v404 = {};
	for v584, v585 in pairs(v403) do
		if v585 then
			table.insert(v404, v584);
		end
	end
	v11.WBMutation = v404;
	v90();
end});
local function v189(v406)
	if not v406 then
		return "";
	end
	local v407 = string.gsub(v406, v7("\235\20\67\81\136\204\0\227\236\18\93", "\205\143\125\48\50\231\190\100"), v7("\201\168\27\14\242\173\215\187\211\166\90\12\238", "\194\161\199\116\101\129\131\191"));
	v407 = string.gsub(v407, v7("\232\45\219\171\248\176\232\37\216\184\185\161\227\41", "\194\140\68\168\200\151"), v7("\74\244\218\46\230\12\243\204\55\244\12\242\218", "\149\34\155\181\69"));
	return v407;
end
local function v190(v408)
	local v409 = 0 + 0;
	local v410;
	while true do
		local v586 = 237 - (58 + 179);
		while true do
			if (v586 == (0 - 0)) then
				if (v409 == (1253 - (677 + 576))) then
					if not v408 then
						return "";
					end
					v410 = string.gsub(v408, v7("\7\244\198\249\12\239\209\180\0\242\216", "\154\99\157\181"), v7("\133\0\227\171\255\195\7\245\178\237\195\6\227", "\140\237\111\140\192"));
					v409 = 1 + 0;
				end
				if (1 == v409) then
					local v979 = 0 - 0;
					while true do
						if (v979 == 0) then
							v410 = string.gsub(v410, v7("\2\16\110\27\9\11\121\25\22\9\51\27\9\20", "\120\102\121\29"), v7("\164\236\182\48\191\173\177\34\190\226\247\50\163", "\91\204\131\217"));
							return v410;
						end
					end
				end
				break;
			end
		end
	end
end
v174:CreateInput(v7("\249\250\87\220\188\210\245\142\202\103\248", "\158\174\159\53\180\211\189"), v7("\98\252\254\201\114\245\118\244\254\222\120\167\86\189\250\216\117\189\93\242\230", "\213\50\157\141\189\23"), nil, function(v411)
	local v412 = 0;
	local v413;
	while true do
		if ((222 - (88 + 132)) == v412) then
			if v413 then
				local v924 = 0 + 0;
				local v925;
				while true do
					if (v924 == (4 - 3)) then
						v95:Notify({[v7("\0\196\77\209\62", "\91\84\173\57\189")]=v7("\39\188\14\244\175\217\27\249\56\249\179\194", "\182\112\217\108\156\192"),[v7("\142\13\91\236\153\163\24\92\230\132\164", "\235\202\104\40\143")]=v7("\57\142\8\173\77\142\22\187\8\143\91\170\8\133\15\249\30\158\24\186\8\152\8\191\24\135\23\160\76", "\217\109\235\123"),[v7("\3\156\108\87\100\217\194\179", "\221\71\233\30\54\16\176\173")]=(10 - 7)});
						break;
					end
					if (v924 == 0) then
						v925 = {[v7("\234\47\144\172\119", "\196\158\70\228\192\18")]=v7("\100\122\38\14\238\111\125\57\97\246\97\31\50\97\247\100\122\50\122\240\101\113\81\122\252\121\107", "\185\42\63\113\46"),[v7("\208\216\50\58\9\221\205\53\48\20\218", "\123\180\189\65\89")]=v7("\238\153\232\253\201\234\153\242\164\128\209\204\254\235\158\130\159\229\231\138\199\159\227\226\156\206\128\233\164\138\205\130\254\225\138\214\137\244\164\159\203\141\176\204\144\208\141\176\214\140\206\141\233\164\185\208\131\232\253\201\225\132\241\234\135\199\128\190", "\233\162\236\144\132"),[v7("\177\203\242\21\171", "\63\210\164\158\122\217\150")]=tonumber(v7("\99\211\166\188\111\222\99\155", "\152\83\171\150\140\41")),[v7("\132\234\140\39\209\9", "\104\226\133\227\83\180\123")]={[v7("\23\14\59\68", "\48\99\107\67")]=v7("\242\179\101\201\109\83\203\164\61\198\126\53\136", "\27\190\198\29\176\77")},[v7("\251\66\240\49\186\90\238\70\237", "\46\143\43\157\84\201")]=DateTime.now():ToIsoDate()};
						pcall(function()
							v413({[v7("\98\106\90", "\168\55\24\54\162\63\115")]=v190(v411),[v7("\58\255\52\136\221\202", "\174\119\154\64\224\178")]=v7("\26\81\246\79", "\132\74\30\165\27\101\199\122"),[v7("\7\226\254\163\162\167\167", "\212\79\135\159\199\199\213")]={[v7("\90\175\187\83\89\217\12\52\148\172\87\89", "\120\25\192\213\39\60\183")]=v7("\25\80\47\68\17\67\62\92\17\79\49\7\18\83\48\70", "\40\120\32\95")},[v7("\24\164\61\99", "\127\90\203\89\26\207")]=game:GetService(v7("\245\33\187\219\58\248\207\35\166\200\12", "\157\189\85\207\171\105")):JSONEncode({[v7("\211\178\221\167\13\199\172\221", "\99\166\193\184\213")]=v7("\250\162\152\162\76\162\195\181\192\149\3\158\223\177\137\190\30", "\234\182\215\224\219\108"),[v7("\193\151\186\33\193\147\132\32\210\141", "\85\160\225\219")]=v7("\84\17\151\217\37\134\4\19\12\205\192\59\219\94\78\75\128\198\59\147\96\13\50\211\199\20\136\5\76\11\132", "\43\60\101\227\169\86\188"),[v7("\117\197\211\186\94\223", "\87\16\168\177\223\58\172\217")]={v925}})});
						end);
						v924 = 1 - 0;
					end
				end
			end
			break;
		end
		if (v412 == (1 + 0)) then
			v90();
			v413 = (syn and syn.request) or (http and http.request) or http_request or request or fluxus.request;
			v412 = 2;
		end
		if (v412 == (947 - (652 + 295))) then
			if (not v411 or (v411 == "")) then
				return;
			end
			v11.WebhookURL = v411;
			v412 = 1 + 0;
		end
	end
end);
v174:CreateToggle(v7("\17\242\95\189\56\249\30\136\49\254\86\176\59\247", "\223\84\156\62"), v11.AWebhook, v7("\247\255\246\212\161\62\150\235\231\223\191\52\217\247\241\157\180\52\216\250\235\218\162\41\215\232\235\210\185\40", "\91\182\156\130\189\215"), function(v414)
	v11.AWebhook = v414;
	v90();
end);
v11.StatusFilterBrainrot = v11.StatusFilterBrainrot or {v7("\95\125\181", "\53\30\19\204")};
v11.StatusFilterRarity = v11.StatusFilterRarity or {v7("\216\238\105", "\199\153\128\16\228")};
v11.AutoStatusInterval = v11.AutoStatusInterval or 15;
v11.AutoStatusWebhook = v11.AutoStatusWebhook or false;
local v195 = 740 - (372 + 368);
v174:AddDropdown(v7("\226\62\228\13\178\194\12\236\21\179\212\56\199\11\166\216\36\247\22\179", "\199\177\74\133\121"), {[v7("\140\204\164\234", "\74\216\169\220\158\87\166")]=v7("\220\49\18\47\81\237\49\83\10\83\228\55\22\62\0\168\1\1\45\83\230\49\28\56", "\58\136\67\115\76"),[v7("\199\171\212\76\128\51", "\61\145\202\184\57\229\64\203")]=v96.BrainrotOptions,[v7("\120\87\143\70\73\94\157", "\39\60\50\233")]=v11.StatusFilterBrainrot,[v7("\55\38\175\56\139", "\195\122\83\195\76\226\72\210")]=true,[v7("\215\209\58\236\34\236\213\57\242\36", "\65\132\180\91\158")]=true,[v7("\38\125\221\34\7\125\210\37", "\78\101\28\177")]=function(v416)
	local v417 = 0 + 0;
	local v418;
	while true do
		if (v417 == 1) then
			v11.StatusFilterBrainrot = v418;
			if v90 then
				v90();
			end
			break;
		end
		if (v417 == (1130 - (542 + 588))) then
			v418 = {};
			for v859, v860 in pairs(v416) do
				if v860 then
					table.insert(v418, v859);
				end
			end
			v417 = 1;
		end
	end
end});
v174:AddDropdown(v7("\22\160\225\69\48\167\198\88\41\160\229\67\23\181\242\88\49\173", "\49\69\212\128"), {[v7("\35\9\200\230", "\129\119\108\176\146")]=v7("\8\221\6\206\46\11\14\124\233\14\193\49\11\14\102\143\53\204\55\7\8\37", "\124\92\175\103\173\69\110"),[v7("\247\57\15\34\196\43", "\87\161\88\99")]=v96.RarityOptions,[v7("\54\252\233\205\162\220\55", "\67\114\153\143\172\215\176")]=v11.StatusFilterRarity,[v7("\147\183\226\26\183", "\110\222\194\142")]=true,[v7("\36\220\26\187\81\169\22\219\23\172", "\193\119\185\123\201\50")]=true,[v7("\84\9\245\42\13\120\28\124", "\127\23\104\153\70\111\25")]=function(v419)
	local v420 = {};
	for v587, v588 in pairs(v419) do
		if v588 then
			table.insert(v420, v587);
		end
	end
	v11.StatusFilterRarity = v420;
	if v90 then
		v90();
	end
end});
v174:CreateSlider(v7("\40\18\178\160\107\31\178\189\13\71\143\161\63\41\165\165\8\11\230\231\6\37\185\160\64", "\211\105\103\198\207\75\76\215"), 819 - (6 + 812), 120, v11.AutoStatusInterval, function(v422)
	local v423 = 0;
	while true do
		if (v423 == (1705 - (1599 + 106))) then
			v11.AutoStatusInterval = v422;
			v195 = tick() + (v422 * (166 - 106));
			v423 = 1 + 0;
		end
		if (v423 == 1) then
			if v90 then
				v90();
			end
			break;
		end
	end
end);
local function v196(v424)
	if (not v11.WebhookURL or (v11.WebhookURL == "")) then
		if v424 then
			v95:Notify({[v7("\250\174\164\227\123", "\214\174\199\208\143\30\108\218")]=v7("\52\150\25\165\183", "\41\113\228\107\202\197\54\184"),[v7("\78\136\32\72", "\60\26\237\88")]=v7("\239\47\118\238\161\215\33\52\211\156\244\106\113\235\190\204\51\53", "\206\184\74\20\134"),[v7("\28\241\252\176\231\67\55\194", "\172\88\132\142\209\147\42\88")]=(2 + 1)});
		end
		return;
	end
	task.spawn(function()
		local v589 = {};
		local v590 = 0;
		local v591 = {};
		if v107.Backpack then
			for v861, v862 in ipairs(v107.Backpack:GetChildren()) do
				table.insert(v591, v862);
			end
		end
		if v107.Character then
			for v863, v864 in ipairs(v107.Character:GetChildren()) do
				table.insert(v591, v864);
			end
		end
		local v592;
		pcall(function()
			v592 = require(game:GetService(v7("\181\143\220\1\63\246\191\147\143\200\62\34\250\172\134\141\201", "\222\231\234\172\109\86\149")).Shared.Data.EntitiesData);
		end);
		local function v593(v686, v687)
			if (not v686 or (#v686 == (0 - 0)) or table.find(v686, v7("\204\225\217", "\120\141\143\160")) or table.find(v686, v7("\97\160\186", "\50\32\204\214"))) then
				return true;
			end
			return table.find(v686, v687) ~= nil;
		end
		for v688, v689 in ipairs(v591) do
			if (v689:IsA(v7("\178\72\58\117", "\113\230\39\85\25\211")) and v689:GetAttribute(v7("\249\142\47\204", "\43\190\219\102\136\71\171\203"))) then
				local v865 = v689.Name;
				local v866 = v689:GetAttribute(v7("\16\127\34\80\54\103", "\57\66\30\80"));
				local v867 = v689:GetAttribute(v7("\4\205\180\20\144\48\251\138", "\228\73\184\192\117\228\89\148")) or v7("\225\134\123\17", "\116\175\233\21");
				if ((not v866 or (v866 == v7("\203\246\181\72\212\38\49", "\95\158\152\222\38\187\81")) or (v866 == "")) and v592 and v592.Brainrots) then
					local v980 = v592.Brainrots[v865];
					if v980 then
						v866 = v980.Rarity;
					end
				end
				v866 = v866 or v7("\205\179\62\188\172\223\246", "\168\152\221\85\210\195");
				if (v593(v11.StatusFilterBrainrot, v865) and v593(v11.StatusFilterRarity, v866)) then
					local v981 = 0 - 0;
					while true do
						if (v981 == (0 + 0)) then
							v590 = v590 + 1 + 0;
							if not v589[v866] then
								v589[v866] = {};
							end
							v981 = 1;
						end
						if (v981 == 1) then
							if not v589[v866][v865] then
								v589[v866][v865] = {};
							end
							v589[v866][v865][v867] = (v589[v866][v865][v867] or 0) + 1;
							break;
						end
					end
				end
			end
		end
		local v594 = "0";
		local v595 = tostring(v115 or (1 + 0));
		pcall(function()
			local v690 = 0 + 0;
			local v691;
			while true do
				if (v690 == 1) then
					if (v113 and (type(v113) == v7("\248\171\9\0\94\78", "\60\150\222\100\98\59")) and (v113 > (0 + 0))) then
						v594 = v691(v113);
					else
						local v1034 = v107:FindFirstChild(v7("\73\57\86\82\222\168\34\81\61\67\69", "\81\37\92\55\54\187\218"));
						if v1034 then
							local v1136 = v1034:FindFirstChild(v7("\35\75\164\57\146", "\225\96\36\205\87")) or v1034:FindFirstChild(v7("\202\167\81\113", "\105\137\198\34\25\28\47"));
							if v1136 then
								if (type(v1136.Value) == v7("\2\189\83\127\206\22", "\160\113\201\33\22")) then
									v594 = v1136.Value;
								else
									v594 = v691(tonumber(v1136.Value) or 0);
								end
							end
						end
					end
					break;
				end
				if (v690 == (0 + 0)) then
					v691 = nil;
					function v691(v982)
						if (type(v982) ~= v7("\165\203\248\133\174\204", "\231\203\190\149")) then
							return tostring(v982);
						end
						if (v982 < (2929 - (1690 + 239))) then
							return tostring(v982);
						end
						local v983 = {"K","M","B","T","Q",v7("\252\52", "\123\173\93\131\145\220\149"),"S",v7("\37\212", "\153\118\164\141\65\20")};
						local v984 = math.floor(math.log10(v982) / (1871 - (1736 + 132)));
						return string.format(v7("\171\124\212\228\178\19", "\96\142\82\230\130\151"), v982 / ((6 + 4) ^ (v984 * (9 - 6))), v983[v984] or ""):gsub(v7("\10\254\31\18", "\142\47\208\47\34\132"), "");
					end
					v690 = 4 - 3;
				end
			end
		end);
		local v596 = {};
		local v597 = {[v7("\225\86\167\169\166\186\218", "\205\180\56\204\199\201")]=(0 + 0),[v7("\160\209\49\21\140\208", "\120\227\190\92")]=(33 - (27 + 5)),[v7("\8\82\28\116\46\81\214\236", "\130\93\60\127\27\67\60\185")]=(1 + 1),[v7("\122\51\42\75", "\29\40\82\88\46\128\35")]=3,[v7("\30\85\221\30", "\216\91\37\180\125\97")]=(3 + 1),[v7("\9\115\27\198\89\33\119\14\218", "\55\69\22\124\163")]=(2 + 3),[v7("\85\202\72\224\214\114", "\148\24\179\60\136\191\17\48")]=(2 + 4),[v7("\159\51\237\168\255\177\43\245", "\150\210\74\153\192")]=(5 + 1),[v7("\208\205\59\152\112\110", "\212\131\168\88\234\21\26")]=(1124 - (771 + 346)),[v7("\97\125\159\133\54\34", "\71\37\20\233\236\88")]=(1642 - (1577 + 57)),[v7("\238\67\188\19\83\248\69\93\193", "\60\173\38\208\118\32\140\44")]=(15 - 6),[v7("\100\38\228\193\46\206\77", "\175\33\82\129\179\64")]=(1090 - (684 + 396))};
		local v598 = {};
		for v692, v693 in pairs(v589) do
			table.insert(v598, v692);
		end
		table.sort(v598, function(v694, v695)
			return (v597[v694] or (0 - 0)) < (v597[v695] or 0);
		end);
		for v696, v697 in ipairs(v598) do
			local v698 = "";
			local v699 = true;
			local v700 = {};
			for v752, v753 in pairs(v589[v697]) do
				table.insert(v700, v752);
			end
			table.sort(v700);
			for v754, v755 in ipairs(v700) do
				local v756 = 1196 - (700 + 496);
				local v757;
				local v758;
				while true do
					if (v756 == (0 + 0)) then
						v757 = v7("\164\165", "\210\142\143\80\175\92") .. v755 .. "**\n";
						v758 = {};
						v756 = 253 - (65 + 187);
					end
					if (v756 == (942 - (827 + 112))) then
						if ((#v698 + #v757) > (663 + 287)) then
							local v1094 = (v699 and ("━━━━━━━━ " .. v697:upper() .. " ━━━━━━━━")) or v7("\198\16\52", "\22\153\48\107\108\23\35");
							table.insert(v596, {[v7("\0\132\182\31", "\137\110\229\219\122\31\21\33")]=v1094,[v7("\12\188\52\110\51", "\30\122\221\88\27\86\43\68")]=v698,[v7("\49\38\231\143\54\45", "\230\88\72\139")]=false});
							v698 = v757;
							v699 = false;
						else
							v698 = v698 .. v757;
						end
						break;
					end
					if (v756 == (2 - 1)) then
						for v1035, v1036 in pairs(v589[v697][v755]) do
							table.insert(v758, v1035);
						end
						table.sort(v758);
						v756 = 2;
					end
					if (v756 == (5 - 3)) then
						for v1037, v1038 in ipairs(v758) do
							local v1039 = 0;
							local v1040;
							local v1041;
							while true do
								if (v1039 == (4 - 3)) then
									v757 = v757 .. v7("\13\150\23\254\44\85\71\223\53\229\120\84\19", "\52\51\182\90\139\88") .. v1041 .. v7("\182\161", "\35\150\217\176\135") .. v1040 .. " `\n";
									break;
								end
								if (v1039 == 0) then
									local v1158 = 0 + 0;
									while true do
										if (v1158 == (1 + 0)) then
											v1039 = 1197 - (551 + 645);
											break;
										end
										if (v1158 == (343 - (166 + 177))) then
											v1040 = v589[v697][v755][v1038];
											v1041 = (((v1038 == v7("\151\230\253\195", "\166\217\137\147")) or (v1038 == "")) and v7("\205\172\50\139\228\82\226\183\123\169\255", "\38\131\195\18\198\145")) or v1038;
											v1158 = 1857 - (1361 + 495);
										end
									end
								end
							end
						end
						v757 = v757 .. "\n";
						v756 = 7 - 4;
					end
				end
			end
			if (v698 ~= "") then
				local v868 = 0;
				local v869;
				while true do
					if (v868 == (0 + 0)) then
						v869 = (v699 and ("━━━━━━━━ " .. v697:upper() .. " ━━━━━━━━")) or v7("\77\244\41", "\56\18\212\118\123\99\104");
						table.insert(v596, {[v7("\16\232\245\214", "\190\126\137\152\179\191")]=v869,[v7("\62\3\126\222\175", "\32\72\98\18\171\202")]=v698,[v7("\13\134\62\125\249\1", "\151\100\232\82\20")]=false});
						break;
					end
				end
			end
		end
		if (v590 == (0 - 0)) then
			table.insert(v596, {[v7("\113\216\251\13", "\104\31\185\150")]=v7("\245\183\229\242\233\216\239\210\197\249\214\250\247\216\249", "\160\188\217\147\151\135\172\128"),[v7("\25\220\28\229\63", "\169\111\189\112\144\90")]=v7("\227\140\101\175\173\129\0\140\223\140\49\190\255\141\8\150\206\139\32\169\255\153\6\151\223\195\35\164\179\148\12\144\131", "\226\173\227\69\205\223\224\105"),[v7("\81\48\46\82\193\30", "\123\56\94\66\59\175")]=false});
		end
		table.insert(v596, {[v7("\244\66\126\228", "\225\154\35\19\129\122\158")]="💪 Kick Power",[v7("\76\1\231\66\240", "\84\58\96\139\55\149\135\176")]=(v7("\19\63\163\48\65\216\59\1\113\227", "\94\115\95\195\96\46\175") .. v595 .. v7("\67\75\63", "\128\35\43\95\93\78\77\231")),[v7("\173\19\58\61\25\123", "\201\196\125\86\84\119\30")]=true});
		table.insert(v596, {[v7("\205\239\9\186", "\223\163\142\100")]="🎒 Total Item",[v7("\148\23\207\164\189", "\216\226\118\163\209")]=(v7("\190\240\27", "\95\222\144\123\97\55\16") .. v590 .. v7("\89\166\168\66\234\23\150\181\87\227\25\132", "\131\121\228\218\35")),[v7("\208\222\46\8\119\30", "\123\185\176\66\97\25")]=true});
		table.insert(v596, {[v7("\198\14\20\84", "\81\168\111\121\49\117\79\56")]="💸 Total Cash",[v7("\209\11\233\163\194", "\214\167\106\133")]=(v7("\41\56\76\11", "\185\73\88\44\47\84\31") .. v594 .. v7("\136\215\26", "\159\232\183\122\192\179")),[v7("\45\60\164\40\42\55", "\65\68\82\200")]=true});
		local v599 = {[v7("\49\89\102\44\202", "\30\69\48\18\64\175\175")]=v7("\220\37\12\248\123\242\62\30\229\53\226\35\11\172\18\254\58\26\226\47\255\62\6", "\91\144\76\127\140"),[v7("\227\7\74\46\193", "\176\128\104\38\65\179\218\181")]=tonumber(v7("\128\220\228\51\133\145\146\69", "\117\176\164\162")),[v7("\130\203\0\252\222\106", "\25\228\162\101\144\186")]=v596,[v7("\65\59\184\9\247", "\132\40\86\217\110\146")]={[v7("\107\217\43", "\62\30\171\71\220\199\19\156")]=v7("\72\81\184\38\78\147\96\2\67\65\162\120\89\192\60\78\79\87\168\55\77\217\97\78\79\72\227\55\73\221\46\78\72\72\169\56\73\218\96\28\21\20\254\96\9\144\122\25\24\23\245\98\11\156\126\20\17\17\227\103\8\152\125\27\22\21\250\98\5\157\118\24\17\16\251\100\9\145\96\67\79\99\165\58\73\204\61\3\74\85\171\105\88\209\114\27\65\23\248\51\11\145\125\11\73\86\241\96\92\155\124\20\21\21\254\112\85\196\114\76\25\65\251\48\12\205\41\31\25\70\168\53\88\157\41\27\17\16\168\51\10\202\122\30\66\17\175\52\92\205\119\26\21\20\169\101\11\204\122\73\70\16\169\97\89\204\120\79\17\23\254\110\94\145\127\75\22\21\249\97\4\205\122\11", "\45\32\37\204\86\61\169\79")},[v7("\83\90\10\168\176\110", "\28\53\53\101\220\213")]={[v7("\25\89\16\85", "\191\109\60\104\33\58\193\48")]=v7("\171\194\0\254\199\231\10\226\138\222\13\234\199\246\62\204\199\229\29\247\136\197\12\226\149", "\135\231\183\120")},[v7("\242\3\65\225\38\14\168\235\26", "\201\134\106\44\132\85\122")]=DateTime.now():ToIsoDate()};
		local v600 = (syn and syn.request) or (http and http.request) or http_request or request or fluxus.request;
		if v600 then
			local v759 = 0 + 0;
			local v760;
			local v761;
			local v762;
			while true do
				if (v759 == (224 - (148 + 76))) then
					local v985 = 0 - 0;
					while true do
						if (v985 == 1) then
							v759 = 1;
							break;
						end
						if (v985 == (0 - 0)) then
							v760 = 0;
							v761 = nil;
							v985 = 1 + 0;
						end
					end
				end
				if (v759 == 1) then
					v762 = nil;
					while true do
						if (v760 == 0) then
							v761, v762 = pcall(function()
								return v600({[v7("\3\30\123", "\67\86\108\23\95\97\108\168")]=v11.WebhookURL,[v7("\137\61\88\2\171\32", "\48\196\88\44\106\196\68\181")]=v7("\178\240\239\23", "\76\226\191\188\67\224\196\194"),[v7("\241\45\6\244\248\203\59", "\157\185\72\103\144")]={[v7("\122\188\132\110\173\191\77\254\190\99\184\180", "\209\57\211\234\26\200")]=v7("\0\222\182\141\89\209\0\218\175\142\94\157\11\221\169\143", "\178\97\174\198\225\48")},[v7("\237\89\0\232", "\111\175\54\100\145\24\134")]=game:GetService(v7("\107\13\52\5\112\28\50\3\74\26\37", "\117\35\121\64")):JSONEncode({[v7("\200\174\235\196\45\78\208\184", "\47\189\221\142\182\67")]=v7("\12\170\63\210\8\136\6\2\96\139\53\202\75\162\37\59", "\73\64\223\71\171\40\201\64"),[v7("\15\128\198\92\164\110", "\29\106\237\164\57\192")]={v599}})});
							end);
							if (v424 and v761) then
								v95:Notify({[v7("\133\173\243\182\208", "\146\209\196\135\218\181\178\192")]=v7("\30\37\128\18\85\180\62", "\199\77\80\227\113\48"),[v7("\30\58\70\217", "\173\74\95\62")]=v7("\239\23\74\51\197\19\179\212\0\28\4\206\23\179\212\13\28\37\206\9\168\135", "\220\166\121\60\86\171\103"),[v7("\205\23\47\177\47\195\21\231", "\122\137\98\93\208\91\170")]=3});
							end
							break;
						end
					end
					break;
				end
			end
		end
	end);
end
v174:CreateToggle(v7("\166\244\8\64\149\129\172\196\131\161\44\93\218\181\187\207\148", "\170\231\129\124\47\181\210\201"), v11.AutoStatusWebhook, v7("\184\190\52\52\25\106\152\175\59\36\31\57\203\175\53\112\46\35\152\184\53\34\14\106\137\186\41\53\14\106\132\181\122\36\3\39\142\169", "\74\235\219\90\80\106"), function(v425)
	local v426 = 0;
	while true do
		if (v426 == (280 - (111 + 168))) then
			if v90 then
				v90();
			end
			break;
		end
		if (v426 == (0 + 0)) then
			v11.AutoStatusWebhook = v425;
			v195 = tick() + (v11.AutoStatusInterval * (6 + 54));
			v426 = 1 - 0;
		end
	end
end);
v174:CreateButton(v7("\120\198\72\47\122\199\127\252\72\131\111\41\59\247\113\247\94\131\117\52\45", "\146\44\163\59\91\90\148\26"), function()
	v196(true);
end);
task.spawn(function()
	while v11.HubRunning do
		local v601 = 0;
		while true do
			if (v601 == (0 + 0)) then
				task.wait(1 + 0);
				if (v11.AutoStatusWebhook and (v11.WebhookURL ~= "")) then
					if (tick() >= v195) then
						v196(false);
						v195 = tick() + (v11.AutoStatusInterval * 60);
					end
				end
				break;
			end
		end
	end
end);
v175:CreateToggle(v7("\83\29\139\193\107\122\34\171\149", "\41\21\77\216\225"), v11.AFPSBoost, v7("\56\66\101\64\6\13\117\87\21\93\122\76\23\94\50\67\27\95\50\72\21\85\123\72\1\64\50\74\4\89\123\72\29\87\115\81\29\66\124", "\37\116\45\18"), function(v427)
	local v428 = 0;
	while true do
		if (v428 == 1) then
			if v95 then
				v95:SetPotatoMode(v427);
				if (v427 and v11.ARTXShader) then
					local v1042 = 0 + 0;
					while true do
						if (v1042 == (0 - 0)) then
							v11.ARTXShader = false;
							v90();
							break;
						end
					end
				end
			end
			break;
		end
		if (v428 == 0) then
			v11.AFPSBoost = v427;
			v90();
			v428 = 1 + 0;
		end
	end
end);
v175:CreateToggle(v7("\253\203\110\226\152\199\254\82\167\185", "\203\175\159\54\194"), v11.ARTXShader, v7("\90\205\13\50\76\78\214\126\142\26\46\73\91\205\118\142\30\58\87\74\130\104\198\24\63\95\93\209", "\162\27\174\121\91\58\47"), function(v429)
	local v430 = 932 - (147 + 785);
	local v431;
	while true do
		if ((666 - (483 + 183)) == v430) then
			v431 = 0 - 0;
			while true do
				if (v431 == (0 + 0)) then
					v11.ARTXShader = v429;
					v90();
					v431 = 1912 - (1790 + 121);
				end
				if (v431 == (3 - 2)) then
					if v95 then
						local v1095 = 1539 - (259 + 1280);
						while true do
							if (v1095 == (1584 - (160 + 1424))) then
								v95:SetRTXMode(v429);
								if (v429 and v11.AFPSBoost) then
									local v1278 = 0 + 0;
									while true do
										if ((0 + 0) == v1278) then
											v11.AFPSBoost = false;
											v90();
											break;
										end
									end
								end
								break;
							end
						end
					end
					break;
				end
			end
			break;
		end
	end
end);
v175:CreateToggle(v7("\242\203\11\252\127\248\245\238", "\185\179\165\127\149\95"), v11.AntiAFK, v7("\114\122\194\228\27\84\97\202\248\14\17\119\214\228\22\66\102\202\231\87\69\125\202\180\69\1\56\194\253\25\68\97\202\180\37\94\119\195\251\15\17\124\203\248\18\17\126\198\247\28\31", "\119\49\21\175\148"), function(v432)
	local v433 = 770 - (479 + 291);
	local v434;
	while true do
		if (v433 == (0 - 0)) then
			v434 = 971 - (569 + 402);
			while true do
				if (0 == v434) then
					v11.AntiAFK = v432;
					v90();
					break;
				end
			end
			break;
		end
	end
end);
task.spawn(function()
	task.wait(2);
	if (v11.AFPSBoost and v95) then
		v95:SetPotatoMode(true);
	elseif (v11.ARTXShader and v95) then
		v95:SetRTXMode(true);
	end
end);
local v197 = nil;
local v198 = nil;
local function v199()
	if v197 then
		v197:Disconnect();
	end
	v197 = v108.Heartbeat:Connect(function(v602)
		if (not v11.HubRunning or not v198 or not v198.Parent) then
			return;
		end
		local v603 = v107.Character;
		local v604 = v603 and v603:FindFirstChild(v7("\127\160\27\92\35\70\131\241\101\186\25\73\29\72\152\225", "\149\55\213\118\61\77\41\234"));
		local v605 = v603 and v603:FindFirstChild(v7("\53\19\199\199\231\54\166\31", "\123\125\102\170\166\137\89\207"));
		if (not v604 or not v605 or (v605.Health <= (1305 - (635 + 670)))) then
			local v765 = 0;
			while true do
				if (v765 == (0 - 0)) then
					v198 = nil;
					return;
				end
			end
		end
		local v606 = v198.Position;
		local v607 = (Vector3.new(v606.X, 0 - 0, v606.Z) - Vector3.new(v604.Position.X, 598 - (42 + 556), v604.Position.Z)).Magnitude;
		local v608 = (v11.VolcanoTweenSpeed or (1486 - (1246 + 155))) * v602;
		if (v607 > (735 - (31 + 701))) then
			local v766 = (Vector3.new(v606.X, 0 - 0, v606.Z) - Vector3.new(v604.Position.X, 499 - (393 + 106), v604.Position.Z)).Unit;
			local v767 = v766 * math.min(v608, v607);
			local v768 = v604.Position + v767;
			local v769 = v604.Position.Y;
			local v770 = RaycastParams.new();
			v770.FilterType = Enum.RaycastFilterType.Exclude;
			v770.FilterDescendantsInstances = {v603};
			local v774 = Vector3.new(v768.X, math.max(v604.Position.Y, v606.Y) + (14 - 9), v768.Z);
			local v775 = workspace:Raycast(v774, Vector3.new(0, -15, 0 + 0), v770);
			if v775 then
				v769 = v775.Position.Y + (656 - (269 + 384));
			end
			v604.AssemblyLinearVelocity = Vector3.new(1569 - (598 + 971), 0, 0);
			v604.CFrame = CFrame.new(v768.X, v769, v768.Z);
		end
	end);
end
task.spawn(function()
	if not v107.Character then
		v107.CharacterAdded:Wait();
	end
	task.wait(1 + 1);
	v199();
end);
task.spawn(function()
	local v435 = game:GetService(v7("\126\12\89\36\11\145\186", "\201\46\96\56\93\110\227"));
	local v436 = v435.LocalPlayer:WaitForChild(v7("\139\15\239\224\16\211\156\22\231", "\161\219\99\142\153\117"), 5) or v435.LocalPlayer:FindFirstChildOfClass(v7("\76\189\167\106\200\110\150\179\122", "\173\28\209\198\19"));
	while v11.HubRunning do
		local v609 = 0 - 0;
		while true do
			if ((0 - 0) == v609) then
				task.wait(0.5 - 0);
				if v436 then
					pcall(function()
						for v1096, v1097 in ipairs(v436:GetChildren()) do
							if (v1097:IsA(v7("\70\239\165\190\112\226\144\174\124", "\219\21\140\215")) and v1097.Name:find(v7("\100\173\222\190", "\56\40\216\166\199"))) then
								for v1196, v1197 in ipairs(v1097:GetDescendants()) do
									if (v1197:IsA(v7("\18\177\13\59\10\181\23\42\42", "\79\70\212\117")) and ((v1197.Name == v7("\145\23\237\211\252", "\109\199\118\129\166\153")) or (v1197.Name == v7("\2\181\123\243\50\164\114\242", "\150\81\208\23")))) then
										if ((v1197.Text == v7("\215\202\238\142", "\235\153\165\128")) or (v1197.Text == v7("\154\71\187", "\158\219\41\194\79\38\70\202"))) then
											v1197.Text = v7("\14\104", "\232\35\69\79\98\142\182");
										end
									end
								end
							end
						end
					end);
				end
				break;
			end
		end
	end
end);
task.spawn(function()
	local v437 = 1445 - (800 + 645);
	local v438;
	local v439;
	local v440;
	local v441;
	local v442;
	while true do
		if (v437 == (1 + 0)) then
			pcall(function()
				v439 = require(v438.Modules.HandlerLoader.GameHandler);
			end);
			pcall(function()
				v440 = require(v438.Modules.ServicesLoader.SpeedServiceClient);
			end);
			v437 = 792 - (687 + 103);
		end
		if (v437 == (1166 - (142 + 1020))) then
			while v11.HubRunning do
				task.wait(0.1 - 0);
				if v11.AFarm then
					local v988 = nil;
					pcall(function()
						v988 = require(v438.Modules.UILoader.KickBattlesUI).CurrentStatus;
					end);
					if v11.AAutoBattle then
						if (v988 ~= v7("\243\33\209\111\243\77", "\45\177\64\165\27\159\40")) then
							continue;
						end
					elseif ((v988 == v7("\49\25\13\168\107", "\18\125\118\111\202")) or (v988 == v7("\115\46\92\251\36\168", "\155\48\92\57\154\80\205\167"))) then
						continue;
					end
					local v989 = v442.Character;
					if not v989 then
						continue;
					end
					local v990 = v989:FindFirstChild(v7("\145\216\182\190\246\164\76\189\255\180\176\236\155\68\171\217", "\37\217\173\219\223\152\203"));
					local v991 = v989:FindFirstChild(v7("\33\16\18\55\65\167\255\13", "\150\105\101\127\86\47\200"));
					local v992 = v105.CurrentCamera;
					if (not v990 or not v991 or (v991.Health <= (0 + 0))) then
						continue;
					end
					local v993 = v105:FindFirstChild(v7("\239\224\246\180\212", "\160\174\146\147\213\167")) and v105.Areas:FindFirstChild(v7("\107\237\25\79\62\68\65\224\3", "\33\32\132\122\36\108"));
					if (not v993 or (v992.CameraSubject ~= v991)) then
						continue;
					end
					local v994 = v105:FindFirstChild(v7("\142\21\100\78\111", "\28\217\116\18\43"));
					local v995 = v994 and (#v994:GetChildren() > (513 - (306 + 207)));
					local v996 = v442:FindFirstChild(v7("\226\91\215\77\213\188\27\199\94", "\92\178\55\182\52\176\206"));
					local v997 = v996 and v996:FindFirstChild(v7("\50\0\85", "\117\122\85\17"));
					local v998 = v997 and v997:FindFirstChild(v7("\163\230\41\79\132\200\156\251\37\74", "\189\232\143\74\36\198"));
					local v999 = v991:GetAttribute(v7("\216\175\12\79\194\6\232\130\3\94\255\15\245\173\2\90", "\106\156\202\106\46\183"));
					if not v999 then
						v999 = v991.HipHeight;
						v991:SetAttribute(v7("\25\28\125\50\63\49\13\83\58\58\21\28\114\52\34\41", "\74\93\121\27\83"), v999);
					end
					local v1000 = v442:GetAttribute(v7("\84\181\193\127\112\190", "\30\29\219\134")) or "";
					local v1001 = v995 and (v1000 ~= "");
					if v1001 then
						if (v1000 ~= "") then
							local v1160 = string.split(v1000, ",");
							local v1161 = true;
							if v11.AAutoBattle then
								v1161 = false;
							else
								for v1279 = 1, #v1160, 1406 - (112 + 1292) do
									local v1280 = (v1160[v1279] and string.gsub(v1160[v1279], v7("\107\226\10\176\188\17\85\71\16\180\83\190", "\110\53\199\121\154\148\63\120"), v7("\68\75", "\156\97\122\159\95\57"))) or v7("\251\184\209\246\4\21\49", "\95\174\214\186\152\107\98");
									local v1281 = (v1160[v1279 + 1 + 0] and string.gsub(v1160[v1279 + (953 - (587 + 365))], v7("\183\75\98\193\91\136\196\71\52\152\89\130", "\166\233\110\17\235\115"), v7("\61\95", "\28\24\110\164\161\146\222"))) or v7("\117\204\88\32", "\69\59\163\54");
									if ((v1280 == v7("\133\166\193\68\60\218\184", "\214\208\200\170\42\83\173")) or (v1280 == "")) then
										v1161 = false;
										break;
									end
									if v117(v1280, v1281) then
										v1161 = false;
										break;
									end
								end
							end
							if v1161 then
								v991.HipHeight = v999;
								v992.CameraType = Enum.CameraType.Scriptable;
								v992.CFrame = v993.CFrame * CFrame.new(1715 - (829 + 886), 38 - 23, -25);
								v992.CFrame = CFrame.lookAt(v992.CFrame.Position, v993.Position);
								task.wait(0.2 + 0);
								v991.Health = 0;
								local v1245 = v442.CharacterAdded:Wait();
								local v1246 = v1245:WaitForChild(v7("\241\52\127\161\123\214\40\118\146\122\214\53\66\161\103\205", "\21\185\65\18\192"), 19 - 14);
								local v1247 = v1245:WaitForChild(v7("\214\67\80\26\175\241\95\89", "\193\158\54\61\123"), 15 - 10);
								if (v1246 and v1247) then
									local v1325 = 0 + 0;
									while true do
										if (v1325 == (1 + 0)) then
											v992.CameraType = Enum.CameraType.Custom;
											v992.CameraSubject = v1247;
											break;
										end
										if ((0 - 0) == v1325) then
											v1246.CFrame = v993.CFrame * CFrame.new(977 - (613 + 364), 3, 0 + 0);
											task.wait(0.2 + 0);
											v1325 = 1;
										end
									end
								end
							else
								local v1248 = v990.Position;
								local v1249 = v993.Position;
								local v1250 = (Vector3.new(v1248.X, 0 + 0, v1248.Z) - Vector3.new(v1249.X, 0 - 0, v1249.Z)).Magnitude;
								pcall(function()
									v440:SlowMode(false);
								end);
								v991.PlatformStand = true;
								v991.MaxSlopeAngle = 319 - 230;
								while v995 and v11.AFarm and v11.HubRunning do
									local v1282 = task.wait();
									if not (v989 and v991 and (v991.Health > (0 - 0)) and v990) then
										break;
									end
									local v1283 = workspace:FindFirstChild(v7("\2\16\54\188\38", "\217\85\113\64"));
									if not (v1283 and (#v1283:GetChildren() > (0 + 0))) then
										break;
									end
									local v1284 = v990.Position;
									local v1285 = Vector3.new(v1249.X, 1939 - (1467 + 472), v1249.Z) - Vector3.new(v1284.X, 0 - 0, v1284.Z);
									local v1286 = v1285.Magnitude;
									if (v1286 < 3) then
										break;
									end
									local v1287 = math.clamp((1548 - (1077 + 470)) - (v1286 / v1250), 0 + 0, 1 + 0);
									v1287 = v1287 * v1287 * v1287 * v1287;
									local v1288 = math.lerp(v1248.Y + (0.5 - 0), v1249.Y + -5, v1287);
									local v1289 = v991.WalkSpeed;
									local v1290 = v1285.Unit;
									local v1291 = v1290 * v1289 * v1282;
									v990.AssemblyLinearVelocity = Vector3.new(429 - (12 + 417), 0, 0);
									v990.CFrame = CFrame.new(v1284.X + v1291.X, v1288, v1284.Z + v1291.Z);
								end
								v991.PlatformStand = false;
								v991.HipHeight = v999;
								v990.CFrame = v993.CFrame * CFrame.new(0 - 0, -(1.5 + 0), 0 - 0);
								pcall(function()
									v440:SlowMode(true);
								end);
								task.wait(0.3);
							end
						else
							local v1162 = 0 - 0;
							local v1163;
							while true do
								if (v1162 == (0 - 0)) then
									v991.WalkSpeed = 5 + 11;
									v991.MaxSlopeAngle = 89;
									v1162 = 1 + 0;
								end
								if (v1162 == (1 + 0)) then
									v1163 = (v990.Position - v993.Position).Magnitude;
									if (v1163 > (28 - 18)) then
										v198 = v993;
									else
										v198 = nil;
									end
									break;
								end
							end
						end
					else
						local v1099 = 1105 - (924 + 181);
						local v1100;
						while true do
							if (v1099 == (798 - (263 + 534))) then
								v198 = nil;
								v1100 = Vector3.new(v990.Position.X, 0 + 0, v990.Position.Z) - Vector3.new(v993.Position.X, 0 + 0, v993.Position.Z);
								v1099 = 3 - 1;
							end
							if (v1099 == 2) then
								if (v1100.Magnitude > 3) then
									v990.CFrame = v993.CFrame * CFrame.new(0 - 0, 3, 0 + 0);
									task.wait(707.5 - (562 + 145));
								else
									local v1298 = 0 + 0;
									local v1299;
									while true do
										if (v1298 == (1 + 0)) then
											if (v1299 and v122) then
												local v1388 = 0;
												while true do
													if (v1388 == (0 + 0)) then
														pcall(function()
															local v1430 = 0;
															local v1431;
															local v1432;
															local v1433;
															local v1434;
															local v1435;
															local v1436;
															while true do
																if (v1430 == 3) then
																	v1436 = v1434 / v1435;
																	v122:FireServer(v1433, v1436);
																	break;
																end
																if (v1430 == (1 + 1)) then
																	v1435 = 1 + 0;
																	if (v11.KickPowerMode == v7("\96\185\249\212\11", "\197\45\208\154\166\100\159")) then
																		v1435 = 100;
																	elseif (v11.KickPowerMode == v7("\7\245\136\179", "\83\73\148\230\220")) then
																		v1435 = 21735 - 11735;
																	end
																	v1430 = 3;
																end
																if (v1430 == 1) then
																	v1433 = v1431[v1432] or 0.98;
																	v1434 = (v11.CustomKickPowerPercent or (99 + 1)) / (462 - 362);
																	v1430 = 1 + 1;
																end
																if ((0 + 0) == v1430) then
																	v1431 = {[v7("\211\15\252", "\196\145\110\152")]=0.05,[v7("\117\39\250", "\146\56\78\158")]=(1876.25 - (1459 + 417)),[v7("\10\212\64\226", "\58\77\187\47\134")]=(286.45 - (194 + 92)),[v7("\53\39\164\6\241", "\126\114\85\193\103\133\78\52")]=(1385.55 - (1057 + 328)),[v7("\225\195\49\125\200\215\55\118\208", "\24\164\187\82")]=(0.75 - 0),[v7("\193\223\78\172\244\242\206", "\145\145\186\60\202")]=(0.98 - 0),[v7("\197\223\32\9\239\211", "\100\134\176\83")]=0.99};
																	v1432 = v11.TargetMinigameAccuracy or v7("\227\196\80\187\182\22\199", "\117\179\161\34\221\211");
																	v1430 = 1;
																end
															end
														end);
														task.wait(0.5);
														break;
													end
												end
											end
											break;
										end
										if (v1298 == (532 - (5 + 527))) then
											local v1364 = 0 + 0;
											while true do
												if (v1364 == (781 - (342 + 438))) then
													v1298 = 1 + 0;
													break;
												end
												if (v1364 == 0) then
													v1299 = v998 and v998.Visible;
													if (v11.AAutoBattle and (v988 == v7("\105\14\216\212\227\135", "\133\43\111\172\160\143\226"))) then
														local v1421 = 0;
														local v1422;
														local v1423;
														local v1424;
														while true do
															if (v1421 == (1 + 0)) then
																v1424 = nil;
																while true do
																	if (v1422 == 1) then
																		if (v1424 and v1424:FindFirstChild(v7("\231\12\102\11\78\192\162\194", "\167\179\99\22\77\60\161\207")) and v1424.TopFrame:FindFirstChild(v7("\53\118\134\93\94\39\109\138\85\73", "\44\97\31\235\56"))) then
																			v1423 = v1424.TopFrame.TimerFrame.Visible;
																		end
																		if v1423 then
																			v1299 = true;
																		end
																		break;
																	end
																	if (v1422 == 0) then
																		local v1458 = 0;
																		while true do
																			if (v1458 == 0) then
																				v1423 = false;
																				v1424 = v442.PlayerGui:FindFirstChild(v7("\224\170\83\218\226\202\183\68\221\197\216", "\160\171\195\48\177"));
																				v1458 = 1 + 0;
																			end
																			if ((1 - 0) == v1458) then
																				v1422 = 1 + 0;
																				break;
																			end
																		end
																	end
																end
																break;
															end
															if ((0 + 0) == v1421) then
																v1422 = 0 - 0;
																v1423 = nil;
																v1421 = 1 - 0;
															end
														end
													end
													v1364 = 1;
												end
											end
										end
									end
								end
								break;
							end
							if (v1099 == (12 - (6 + 6))) then
								v991.HipHeight = v999;
								v991.MaxSlopeAngle = 134 - 89;
								v1099 = 2 - 1;
							end
						end
					end
				end
			end
			break;
		end
		if (v437 == 2) then
			v441 = game:GetService(v7("\149\150\251\54\85\35\177\138\246\0", "\81\199\227\149\101\48"));
			v442 = game:GetService(v7("\77\94\250\8\243\148\47", "\219\29\50\155\113\150\230\92")).LocalPlayer;
			v437 = 2 + 1;
		end
		if (v437 == (1256 - (206 + 1047))) then
			if not v442.Character then
				v442.CharacterAdded:Wait();
			end
			task.wait(5);
			v437 = 1116 - (470 + 642);
		end
		if (v437 == (0 + 0)) then
			v438 = game:GetService(v7("\75\5\15\241\112\3\30\233\124\4\44\233\118\18\30\250\124", "\157\25\96\127"));
			v439, v440 = nil;
			v437 = 1;
		end
	end
end);
task.spawn(function()
	local v443 = 0;
	local v444;
	local v445;
	while true do
		if ((1067 - (552 + 515)) == v443) then
			v444 = false;
			v445 = {};
			v443 = 1;
		end
		if (v443 == 1) then
			while v11.HubRunning do
				task.wait(0.5 + 0);
				if (v11.APlaceBest and not v444) then
					local v1002 = game:GetService(v7("\1\218\230\236\230\138\50\203\243\228\220\157\60\205\247\231\234", "\233\83\191\150\128\143")):FindFirstChild(v7("\196\142\206\96\8\243", "\109\151\230\175\18"), true);
					if v1002 then
						v1002 = v1002:FindFirstChild(v7("\144\251\66\79\129\167\255\82", "\224\192\154\33\36"), true);
					end
					if v1002 then
						v1002 = v1002:FindFirstChild(v7("\173\81\12\149\140\70\19", "\226\227\52\120"), true);
					end
					if v1002 then
						v1002 = v1002:FindFirstChild(v7("\23\238\250\155\121\128\254\183\17\238\254\165\73\171", "\217\101\139\140\196\42\223\183"), true);
					end
					if not v1002 then
						continue;
					end
					local v1003 = v107.Character;
					local v1004 = v1003 and v1003:FindFirstChild(v7("\50\26\162\27\74\21\6\171", "\36\122\111\207\122"));
					local v1005 = v119();
					if (v1005 and v1003 and v1004 and (v1004.Health > 0)) then
						local v1101 = math.huge;
						local v1102 = nil;
						local v1103 = nil;
						if v1005:FindFirstChild(v7("\63\4\235\172\171", "\84\108\104\132\216\216")) then
							for v1200, v1201 in ipairs(v1005.Slots:GetChildren()) do
								local v1202 = 0 + 0;
								local v1203;
								local v1204;
								while true do
									if (v1202 == (0 + 0)) then
										v1203 = v1201:FindFirstChild(v7("\252\23\199\91\229\160\114\205\9\210", "\34\172\123\166\56\128\196"));
										v1204 = tonumber(string.match(v1201.Name, v7("\225\173\227", "\116\196\201\200\171\42\19\181")));
										v1202 = 1;
									end
									if ((1 + 0) == v1202) then
										if v1204 then
											local v1365 = 0;
											while true do
												if (v1365 == (0 + 0)) then
													if (v445[v1204] and ((tick() - v445[v1204]) < 5)) then
														continue;
													end
													if not v1203 then
														if not v1103 then
															v1103 = v1204;
														end
													elseif v1203:GetAttribute(v7("\95\162", "\124\22\230\155\61\117\96")) then
														local v1439 = v1203:GetAttribute(v7("\236\143", "\149\165\203\134\139\158\141"));
														local v1440 = v1203:GetAttribute(v7("\30\185\84\39\39\165\79\40", "\70\83\204\32")) or v7("\32\142\5\133", "\224\110\225\107");
														local v1441 = v1203:GetAttribute(v7("\216\115\203\52\60", "\164\148\22\189\81\80\164")) or (1 + 0);
														local v1442 = string.format(v7("\247\147\55\136\98\88\74", "\23\210\224\23\211\71\43"), v1439, v1440);
														local v1443 = false;
														if (v11.AProtectFilter and v11.TProtectedBrainrots) then
															for v1453, v1454 in ipairs(v11.TProtectedBrainrots) do
																local v1455 = string.gsub(v1454, v7("\151\195\43\155\67\110\146\181\173\205\85\138\16\56\150", "\144\201\230\112\215\53\75\188"), "");
																if (v1455 == v1442) then
																	v1443 = true;
																	break;
																end
															end
														end
														if not v1443 then
															local v1451 = 1051 - (701 + 350);
															local v1452;
															while true do
																if (v1451 == 0) then
																	v1452 = v154(v1439, v1440, v1441);
																	if (v1452 < v1101) then
																		v1101 = v1452;
																		v1102 = v1204;
																	end
																	break;
																end
															end
														end
													end
													break;
												end
											end
										end
										break;
									end
								end
							end
						end
						local v1104 = nil;
						local v1105 = -1;
						local v1106 = {};
						if v107.Backpack then
							for v1205, v1206 in ipairs(v107.Backpack:GetChildren()) do
								if v1206:IsA(v7("\97\202\22\230", "\197\53\165\121\138\150")) then
									table.insert(v1106, v1206);
								end
							end
						end
						if v1003 then
							local v1164 = 0 + 0;
							local v1165;
							while true do
								if (v1164 == (0 + 0)) then
									v1165 = v1003:FindFirstChildOfClass(v7("\217\208\214\44", "\64\141\191\185"));
									if v1165 then
										table.insert(v1106, v1165);
									end
									break;
								end
							end
						end
						for v1137, v1138 in ipairs(v1106) do
							if (v1138:IsA(v7("\55\229\191\214", "\198\99\138\208\186\151\169")) and (v1138:GetAttribute(v7("\42\192\170\122", "\62\109\149\227")) or (v152[v1138.Name] ~= nil))) then
								local v1207 = v1138:GetAttribute(v7("\222\157\157\213\20\250\135\135", "\96\147\232\233\180")) or v7("\6\55\20\78", "\89\72\88\122\43\237");
								local v1208 = v154(v1138.Name, v1207, 1 + 0);
								if (v1208 > v1105) then
									local v1300 = 0;
									local v1301;
									while true do
										if (v1300 == (0 - 0)) then
											v1301 = 0 - 0;
											while true do
												if (v1301 == 0) then
													v1105 = v1208;
													v1104 = v1138;
													break;
												end
											end
											break;
										end
									end
								end
							end
						end
						local v1107 = nil;
						if (v1104 and v1103) then
							v1107 = v1103;
						elseif (v1104 and v1102 and (v1105 > v1101)) then
							v1107 = v1102;
						end
						if v1107 then
							local v1166 = 0 + 0;
							local v1167;
							while true do
								if (v1166 == (0 - 0)) then
									v444 = true;
									v11.IsPlacingPet = true;
									v1166 = 1;
								end
								if (v1166 == (1 + 1)) then
									while (v1003:FindFirstChildOfClass(v7("\24\180\170\58", "\123\76\219\197\86")) ~= v1104) and (tick() < v1167) do
										task.wait();
									end
									if (v1003:FindFirstChildOfClass(v7("\108\215\26\0", "\95\56\184\117\108\142")) == v1104) then
										local v1344 = 0 + 0;
										while true do
											if (v1344 == (0 - 0)) then
												pcall(function()
													v1002:FireServer(v1107);
												end);
												v445[v1107] = tick();
												break;
											end
										end
									end
									v1166 = 1349 - (281 + 1065);
								end
								if (v1166 == (18 - 14)) then
									v444 = false;
									break;
								end
								if (v1166 == (3 - 2)) then
									v1004:EquipTool(v1104);
									v1167 = tick() + 0.5;
									v1166 = 1213 - (1114 + 97);
								end
								if (v1166 == (3 - 0)) then
									task.wait(0.3);
									v11.IsPlacingPet = false;
									v1166 = 1917 - (279 + 1634);
								end
							end
						end
					end
				end
			end
			break;
		end
	end
end);
task.spawn(function()
	while v11.HubRunning do
		task.wait(1280.5 - (1213 + 67));
		if ((v11.ATrain or v11.ATrainCollect) and not v11.IsPlacingPet and not v11.IsFlashCollecting) then
			local v779 = 191 - (65 + 126);
			local v780;
			local v781;
			while true do
				if (v779 == 0) then
					v780 = v107.Character;
					v781 = v780 and v780:FindFirstChild(v7("\216\215\43\237\254\205\47\232", "\140\144\162\70"));
					v779 = 1;
				end
				if (v779 == (1 + 0)) then
					if (v781 and v135) then
						local v1108 = 1085 - (189 + 896);
						local v1109;
						local v1110;
						local v1111;
						local v1112;
						while true do
							if (v1108 == (1 + 0)) then
								v1111 = {};
								for v1255, v1256 in ipairs(v107.Backpack:GetChildren()) do
									if v1256:IsA(v7("\228\39\86\126", "\142\176\72\57\18")) then
										table.insert(v1111, v1256);
									end
								end
								v1108 = 2;
							end
							if (v1108 == (1965 - (1872 + 91))) then
								if v780 then
									local v1304 = 0 - 0;
									local v1305;
									while true do
										if (v1304 == 0) then
											v1305 = v780:FindFirstChildOfClass(v7("\146\62\31\40", "\68\198\81\112"));
											if v1305 then
												table.insert(v1111, v1305);
											end
											break;
										end
									end
								end
								v1112 = v149();
								v1108 = 3;
							end
							if (v1108 == (0 + 0)) then
								v1109 = nil;
								v1110 = -1;
								v1108 = 1;
							end
							if (v1108 == 3) then
								for v1257, v1258 in ipairs(v1111) do
									for v1306, v1307 in ipairs(v1112) do
										if ((v1307.name == v1258.Name) and (v1306 > v1110)) then
											v1110 = v1306;
											v1109 = v1258;
										end
									end
								end
								if v1109 then
									local v1308 = 0 - 0;
									local v1309;
									while true do
										if (v1308 == (0 + 0)) then
											v1309 = v780:FindFirstChildOfClass(v7("\131\0\191\24", "\125\215\111\208\116\44"));
											if (not v1309 or (v1309.Name ~= v1109.Name)) then
												if v127 then
													pcall(function()
														v127:FireServer(v1109.Name);
													end);
												end
												if (v1109.Parent == v107.Backpack) then
													v781:EquipTool(v1109);
												end
											end
											break;
										end
									end
								end
								break;
							end
						end
					end
					break;
				end
			end
		end
	end
end);
task.spawn(function()
	local v446 = 0 + 0;
	local v447;
	while true do
		if (v446 == (0 - 0)) then
			v447 = false;
			while v11.HubRunning do
				task.wait(76.5 - (22 + 54));
				if (v11.ABuySpeed and v125) then
					if not v447 then
						local v1113 = 0;
						local v1114;
						local v1115;
						local v1116;
						while true do
							if (v1113 == 1) then
								v1116 = nil;
								while true do
									if (v1114 == 1) then
										for v1345, v1346 in ipairs(v1116) do
											local v1347 = v113;
											pcall(function()
												v125:FireServer(v1346);
											end);
											task.wait(0.5);
											if (v113 < v1347) then
												v1115 = true;
												break;
											end
										end
										if not v1115 then
											v447 = true;
											task.delay(11 - 6, function()
												v447 = false;
											end);
										end
										break;
									end
									if (v1114 == (0 - 0)) then
										local v1326 = 0;
										while true do
											if (v1326 == 0) then
												v1115 = false;
												v1116 = {(11 - 8),(1536 - (553 + 981)),1};
												v1326 = 1 + 0;
											end
											if (v1326 == (1 + 0)) then
												v1114 = 1;
												break;
											end
										end
									end
								end
								break;
							end
							if ((0 - 0) == v1113) then
								v1114 = 0 - 0;
								v1115 = nil;
								v1113 = 1;
							end
						end
					end
				else
					task.wait(1898 - (1320 + 577));
				end
			end
			break;
		end
	end
end);
task.spawn(function()
	local v448 = false;
	local v449 = 0;
	while v11.HubRunning do
		task.wait(849.5 - (667 + 182));
		local v610 = v111(tostring((v107.leaderstats and v107.leaderstats:FindFirstChild(v7("\36\72\70\253\107", "\60\103\39\47\147\24")) and v107.leaderstats.Coins.Value) or "0"));
		local v611 = nil;
		if (v11.ABuyBest and v135) then
			local v782 = v107.Character;
			local v783 = nil;
			local v784 = {};
			for v870, v871 in ipairs(v107.Backpack:GetChildren()) do
				table.insert(v784, v871);
			end
			if v782 then
				local v926 = v782:FindFirstChildOfClass(v7("\216\5\248\140", "\46\140\106\151\224\182\147"));
				if v926 then
					table.insert(v784, v926);
				end
			end
			for v872, v873 in ipairs(v784) do
				if (v873:IsA(v7("\223\34\114\78", "\34\139\77\29")) and v135:FindFirstChild(v873.Name)) then
					v783 = v873.Name;
				end
			end
			if v783 then
				local v927 = v149();
				local v928 = 1288 - (1115 + 173);
				for v1008, v1009 in ipairs(v927) do
					if (v1009.name == v783) then
						v928 = v1008;
						break;
					end
				end
				if ((v928 > (0 - 0)) and (v928 < #v927)) then
					v611 = v927[v928 + 1].name;
				elseif ((v928 == (0 + 0)) and (#v927 > (1755 - (1375 + 380)))) then
					v611 = v927[1 + 0].name;
				end
			end
		elseif (v11.ABuyWeights and (v11.TTargetWeight ~= v7("\158\255\19\81", "\73\208\144\125\52"))) then
			v611 = v11.TTargetWeight;
		end
		if (v611 and v126) then
			local v785 = 26 - (12 + 14);
			local v786;
			while true do
				if (v785 == (0 - 0)) then
					v786 = v147(v611);
					if (v610 > v449) then
						v448 = false;
					end
					v785 = 2 - 1;
				end
				if (v785 == 1) then
					if ((v610 >= v786) and not v448) then
						local v1117 = 0 - 0;
						local v1118;
						local v1119;
						while true do
							if (v1117 == (0 - 0)) then
								v1118 = v610;
								pcall(function()
									v126:FireServer(v7("\29\233\131\204\207\4\96\195\37\252", "\171\74\140\234\171\167\112\51"), v611);
								end);
								v1117 = 1 - 0;
							end
							if (v1117 == (2 - 0)) then
								if (v1119 >= v1118) then
									local v1310 = 731 - (354 + 377);
									while true do
										if (v1310 == (0 - 0)) then
											v448 = true;
											v449 = v1119;
											break;
										end
									end
								end
								break;
							end
							if (v1117 == (2 - 1)) then
								task.wait(1983.5 - (263 + 1719));
								v1119 = v111(tostring((v107.leaderstats and v107.leaderstats:FindFirstChild(v7("\12\1\69\81\226", "\205\79\110\44\63\145")) and v107.leaderstats.Coins.Value) or "0"));
								v1117 = 1 + 1;
							end
						end
					end
					break;
				end
			end
		end
	end
end);
task.spawn(function()
	while v11.HubRunning do
		local v612 = 0;
		while true do
			if (v612 == 0) then
				task.wait(2);
				if (v11.APlotUpgrade and v131) then
					pcall(function()
						local v1045 = v113;
						pcall(function()
							v131:FireServer();
						end);
						task.wait(1);
						local v1046 = v113;
						if (v1046 >= v1045) then
							task.wait(369 - (335 + 24));
						end
					end);
				end
				break;
			end
		end
	end
end);
task.spawn(function()
	while v11.HubRunning do
		task.wait(1);
		if (v11.ARebirth and v130) then
			local v787 = 0;
			local v788;
			while true do
				if (v787 == 0) then
					v788 = v146(v116);
					if (v113 >= v788) then
						local v1120 = 951 - (882 + 69);
						while true do
							if (v1120 == (1686 - (657 + 1029))) then
								pcall(function()
									v130:FireServer();
								end);
								task.wait(1205 - (685 + 515));
								break;
							end
						end
					else
						task.wait(1643 - (745 + 893));
					end
					break;
				end
			end
		end
	end
end);
task.spawn(function()
	while v11.HubRunning do
		local v613 = 0 + 0;
		while true do
			if (v613 == (772 - (274 + 498))) then
				task.wait(0.2 + 0);
				if ((v11.A2xTrain or v11.ATrainCollect) and not v11.IsFlashCollecting) then
					local v1010 = 0 + 0;
					local v1011;
					local v1012;
					while true do
						if (v1010 == 0) then
							local v1140 = 1606 - (1035 + 571);
							while true do
								if (v1140 == (1 + 0)) then
									v1010 = 1 + 0;
									break;
								end
								if (v1140 == (0 - 0)) then
									v1011 = v107:FindFirstChild(v7("\151\83\62\209\177\25\131\9\174", "\124\199\63\95\168\212\107\196"));
									v1012 = v1011 and v1011:FindFirstChild(v7("\45\161\80\49\145\231\142\225\7\172\86\41", "\147\102\200\51\90\196\151\233"));
									v1140 = 2 - 1;
								end
							end
						end
						if (1 == v1010) then
							if v1012 then
								for v1259, v1260 in ipairs(v1012:GetChildren()) do
									if (v1260.Name == v7("\25\255\225\216\173", "\91\91\144\143\173\222\128")) then
										pcall(function()
											local v1348 = 0 + 0;
											while true do
												if (v1348 == 0) then
													for v1403, v1404 in pairs(getconnections(v1260.MouseButton1Click)) do
														v1404:Fire();
													end
													for v1405, v1406 in pairs(getconnections(v1260.Activated)) do
														v1406:Fire();
													end
													break;
												end
											end
										end);
									end
								end
							end
							break;
						end
					end
				end
				break;
			end
		end
	end
end);
task.spawn(function()
	local v450 = 0 + 0;
	while v11.HubRunning do
		task.wait(2 - 1);
		if (v11.ACollect and v123) then
			if ((tick() - v450) >= v11.CollectDelay) then
				local v930 = v119();
				local v931 = v107.Character;
				local v932 = v931 and v931:FindFirstChild(v7("\11\181\65\80\165\65\42\164\126\94\164\90\19\161\94\69", "\46\67\192\44\49\203"));
				if (v930 and v932 and v930:FindFirstChild(v7("\38\195\58\182\43\170\22", "\101\100\182\78\194\68\196")) and v930:FindFirstChild(v7("\123\68\63\225\158", "\181\40\40\80\149\237\43\24"))) then
					local v1047 = 0;
					local v1048;
					local v1049;
					while true do
						if (v1047 == (226 - (109 + 115))) then
							for v1209, v1210 in pairs(v1048) do
								table.insert(v1049, {[v7("\79\211\65", "\204\36\182\56\19")]=v1209,[v7("\253\66\217\145", "\114\137\43\188\227\29\88")]=v1210});
							end
							table.sort(v1049, function(v1211, v1212)
								return v1211.key < v1212.key;
							end);
							v1047 = 3;
						end
						if (v1047 == (1399 - (1047 + 352))) then
							v450 = tick();
							v1048 = {};
							v1047 = 1766 - (852 + 913);
						end
						if ((1 + 0) == v1047) then
							for v1213, v1214 in ipairs(v930.Buttons:GetChildren()) do
								if v1214:IsA(v7("\55\179\54\55\138\75\0\1", "\114\117\210\69\82\218\42")) then
									local v1311 = 0;
									local v1312;
									while true do
										if (v1311 == (1345 - (384 + 961))) then
											v1312 = math.floor(v1214.Position.Y / (11 - 6));
											if not v1048[v1312] then
												v1048[v1312] = {};
											end
											v1311 = 1;
										end
										if ((2 - 1) == v1311) then
											table.insert(v1048[v1312], v1214);
											break;
										end
									end
								end
							end
							v1049 = {};
							v1047 = 7 - 5;
						end
						if (v1047 == 3) then
							for v1215, v1216 in ipairs(v1049) do
								local v1217 = v1216.tier;
								local v1218, v1219 = 592 - (591 + 1), 0 + 0;
								local v1220 = 1470 - (218 + 1252);
								for v1261, v1262 in ipairs(v1217) do
									local v1263 = 0 + 0;
									while true do
										if (v1263 == 1) then
											v1220 = v1220 + (357 - (321 + 35));
											break;
										end
										if (v1263 == 0) then
											v1218 = v1218 + v1262.Position.X;
											v1219 = v1219 + v1262.Position.Z;
											v1263 = 1;
										end
									end
								end
								if (v1220 > 0) then
									local v1313 = v1218 / v1220;
									local v1314 = v1219 / v1220;
									local v1315 = v1217[395 - (239 + 155)].Position.Y + 3 + 0;
									v932.CFrame = CFrame.new(v1313, v1315, v1314);
									task.wait(42.15 - (41 + 1));
									for v1327, v1328 in ipairs(v1217) do
										local v1329 = 0;
										local v1330;
										while true do
											if (v1329 == (200 - (80 + 120))) then
												v1330 = tonumber(string.match(v1328.Name, v7("\161\25\227", "\112\132\125\200")));
												if v1330 then
													local v1407 = 0;
													local v1408;
													while true do
														if (v1407 == 0) then
															v1408 = v930.Slots:FindFirstChild(v1328.Name);
															if v1408 then
																local v1447 = 0 + 0;
																local v1448;
																while true do
																	if (v1447 == (0 - 0)) then
																		v1448 = v1408:FindFirstChild(v7("\205\180\242\112\95\241\205\185\225\103", "\149\157\216\147\19\58"));
																		if (v1448 and v1448:FindFirstChildOfClass(v7("\228\137\28\205\197", "\168\169\230\120"))) then
																			local v1464 = 0 + 0;
																			while true do
																				if (v1464 == (0 + 0)) then
																					pcall(function()
																						if firetouchinterest then
																							local v1466 = 0 - 0;
																							while true do
																								if (0 == v1466) then
																									firetouchinterest(v932, v1328, 0 - 0);
																									firetouchinterest(v932, v1328, 4 - 3);
																									break;
																								end
																							end
																						end
																					end);
																					pcall(function()
																						v123:FireServer(v1330);
																					end);
																					break;
																				end
																			end
																		end
																		break;
																	end
																end
															end
															break;
														end
													end
												end
												break;
											end
										end
									end
									task.wait(0.05 - 0);
								end
							end
							break;
						end
					end
				end
			end
		end
	end
end);
task.spawn(function()
	while v11.HubRunning do
		task.wait(0.5 + 0);
		if (v11.ATrainCollect and (tick() >= v11.NextFlashCollect)) then
			local v789 = v107.Character;
			local v790 = v789 and v789:FindFirstChild(v7("\212\152\137\22\242\130\141\19", "\119\156\237\228"));
			local v791 = v789 and v789:FindFirstChild(v7("\235\196\13\127\205\222\9\122\241\222\15\106\243\208\18\106", "\30\163\177\96"));
			local v792 = v119();
			if (v789 and v790 and v791 and v792 and v123) then
				v11.IsFlashCollecting = true;
				local v934 = v11.TrainAnchorCFrame or v791.CFrame;
				local v935 = v789:FindFirstChildOfClass(v7("\46\47\90\133", "\180\122\64\53\233\93\75"));
				local v936 = (v935 and v935.Name) or nil;
				v790:UnequipTools();
				task.wait(0.2);
				if (v792:FindFirstChild(v7("\229\27\28\41\197", "\93\182\119\115")) and v792:FindFirstChild(v7("\160\10\199\152\184\240\145", "\158\226\127\179\236\215"))) then
					local v1050 = 0 + 0;
					local v1051;
					local v1052;
					while true do
						if (v1050 == (1 + 0)) then
							local v1168 = 1226 - (165 + 1061);
							while true do
								if (v1168 == (1 + 0)) then
									v1050 = 2;
									break;
								end
								if (v1168 == (0 + 0)) then
									v1052 = {};
									for v1331, v1332 in pairs(v1051) do
										table.insert(v1052, {[v7("\204\239\109", "\132\167\138\20\27\177\213\220")]=v1331,[v7("\230\220\230\94", "\92\146\181\131\44")]=v1332});
									end
									v1168 = 1;
								end
							end
						end
						if (v1050 == (1643 - (596 + 1047))) then
							local v1169 = 0 + 0;
							while true do
								if (v1169 == (1 + 0)) then
									v1050 = 1 - 0;
									break;
								end
								if ((0 + 0) == v1169) then
									v1051 = {};
									for v1333, v1334 in ipairs(v792.Buttons:GetChildren()) do
										if v1334:IsA(v7("\211\193\218\211\193\193\219\194", "\182\145\160\169")) then
											local v1366 = 0;
											local v1367;
											while true do
												if (v1366 == (737 - (185 + 552))) then
													v1367 = v792.Slots:FindFirstChild(v1334.Name);
													if v1367 then
														local v1425 = 0 + 0;
														local v1426;
														while true do
															if (v1425 == (601 - (507 + 94))) then
																v1426 = v1367:FindFirstChild(v7("\9\44\49\21\162\11\9\33\34\2", "\111\89\64\80\118\199"));
																if (v1426 and v1426:FindFirstChildOfClass(v7("\146\184\10\67\179", "\38\223\215\110"))) then
																	local v1456 = 0 - 0;
																	local v1457;
																	while true do
																		if (v1456 == (0 + 0)) then
																			v1457 = math.floor(v1334.Position.Y / 5);
																			if not v1051[v1457] then
																				v1051[v1457] = {};
																			end
																			v1456 = 1;
																		end
																		if (v1456 == (1 - 0)) then
																			table.insert(v1051[v1457], {[v7("\92\206\24\209\164\80", "\203\62\187\108\165")]=v1334,[v7("\234\120\71\42\95\235\221", "\176\153\20\40\94\17\158")]=tonumber(string.match(v1334.Name, v7("\237\55\240", "\165\200\83\219\51")))});
																			break;
																		end
																	end
																end
																break;
															end
														end
													end
													break;
												end
											end
										end
									end
									v1169 = 1;
								end
							end
						end
						if (v1050 == (1739 - (569 + 1168))) then
							table.sort(v1052, function(v1221, v1222)
								return v1221.key < v1222.key;
							end);
							for v1223, v1224 in ipairs(v1052) do
								local v1225 = v1224.tier;
								local v1226, v1227 = 0 - 0, 0 - 0;
								for v1264, v1265 in ipairs(v1225) do
									v1226 = v1226 + v1265.button.Position.X;
									v1227 = v1227 + v1265.button.Position.Z;
								end
								local v1228 = v1226 / #v1225;
								local v1229 = v1227 / #v1225;
								local v1230 = v1225[1].button.Position.Y + (354 - (118 + 233));
								v791.CFrame = CFrame.new(v1228, v1230, v1229);
								task.wait(0.15);
								for v1266, v1267 in ipairs(v1225) do
									pcall(function()
										local v1317 = 344 - (279 + 65);
										while true do
											if (v1317 == (0 - 0)) then
												if firetouchinterest then
													firetouchinterest(v791, v1267.button, 0);
													firetouchinterest(v791, v1267.button, 1 - 0);
												end
												v123:FireServer(v1267.slotNum);
												break;
											end
										end
									end);
								end
								task.wait(0.05 - 0);
							end
							break;
						end
					end
				end
				v791.CFrame = v934;
				task.wait(0.2);
				if (v936 and v107.Backpack:FindFirstChild(v936)) then
					v790:EquipTool(v107.Backpack[v936]);
				end
				v11.NextFlashCollect = tick() + (v11.TrainCollectDelay * (167 - 107));
				v11.IsFlashCollecting = false;
			end
		end
	end
end);
task.spawn(function()
	local v451 = {};
	local v452 = {};
	local v453 = {};
	local function v454(v614, v615)
		local v616 = 1818 - (1414 + 404);
		while true do
			if (v616 == 1) then
				return table.find(v614, v615) ~= nil;
			end
			if (v616 == 0) then
				if (type(v614) == v7("\88\234\83\143\176\71", "\189\43\158\33\230\222\32\119")) then
					v614 = {v614};
				end
				if (not v614 or (#v614 == (0 + 0)) or table.find(v614, v7("\127\206\84", "\232\62\160\45\49")) or table.find(v614, v7("\57\158", "\193\20\179\149\204")) or table.find(v614, v7("\249\14\143\199", "\162\183\97\225"))) then
					return true;
				end
				v616 = 1 + 0;
			end
		end
	end
	local function v455(v617, v618)
		if not v617:IsA(v7("\29\202\235\251", "\193\73\165\132\151\124\130")) then
			return;
		end
		if v451[v617] then
			local v793 = 0 + 0;
			while true do
				if (v793 == (0 + 0)) then
					if v618 then
						local v1121 = v617:GetAttribute(v7("\234\247\128\127", "\214\173\162\201\59\214"));
						if v1121 then
							local v1170 = 0;
							local v1171;
							while true do
								if (v1170 == (1578 - (420 + 1158))) then
									v1171 = v451[v617];
									if (type(v1171) == v7("\37\108\164\66\195\41\44\119", "\64\67\25\202\33\183")) then
										pcall(v1171);
									end
									break;
								end
							end
						end
					end
					return;
				end
			end
		end
		if not v617:GetAttribute(v7("\206\219\88\152", "\35\137\142\17\220\78\178")) then
			local v794;
			v794 = v617:GetAttributeChangedSignal(v7("\10\123\12\37", "\97\77\46\69")):Connect(function()
				if v617:GetAttribute(v7("\248\234\41\129", "\197\191\191\96")) then
					local v1013 = 0 - 0;
					while true do
						if (v1013 == 0) then
							if v794 then
								v794:Disconnect();
							end
							v455(v617, v618);
							break;
						end
					end
				end
			end);
			task.delay(616 - (406 + 205), function()
				if v794 then
					v794:Disconnect();
				end
			end);
			return;
		end
		local v619 = v617:GetAttribute(v7("\237\28\196\106", "\45\170\73\141\46\56\136"));
		local function v620()
			local v701 = 0;
			local v702;
			local v703;
			local v704;
			local v705;
			while true do
				if (v701 == (10 - 7)) then
					v704 = v617:GetAttribute(v7("\224\206\47\4\223\45\194\213", "\68\173\187\91\101\171")) or v7("\210\0\28\194", "\185\156\111\114\167\41\226\29");
					v705 = v454(v11.TSSellBrainrot, v702) and v454(v11.TSSellRarity, v703) and v454(v11.TSSellMutation, v704);
					v701 = 4;
				end
				if (v701 == (0 + 0)) then
					if (not v11.AAutoFav or not v617.Parent) then
						return;
					end
					if (v452[v619] and ((tick() - v452[v619]) < (0.2 + 0))) then
						return;
					end
					v701 = 2 - 1;
				end
				if (v701 == 4) then
					if v705 then
						if (v617:GetAttribute(v7("\45\4\0\47\166\234\31\0", "\131\107\101\118\64\212")) ~= true) then
							if not table.find(v453, v619) then
								table.insert(v453, v619);
							end
						end
					end
					break;
				end
				if (v701 == 1) then
					v702 = v617.Name;
					v703 = v617:GetAttribute(v7("\179\14\223\236\187\158", "\103\225\111\173\133\207\231"));
					v701 = 63 - (28 + 33);
				end
				if (v701 == (1 + 1)) then
					if (not v703 or (v703 == "")) then
						pcall(function()
							if (v151 and v151.Brainrots and v151.Brainrots[v702]) then
								v703 = v151.Brainrots[v702].Rarity;
							end
						end);
					end
					v703 = v703 or v7("\121\138\254\91\67\147\251", "\53\44\228\149");
					v701 = 1010 - (858 + 149);
				end
			end
		end
		v451[v617] = v620;
		v617.AncestryChanged:Connect(function()
			if not v617.Parent then
				v451[v617] = nil;
			end
		end);
		v620();
		v617:GetAttributeChangedSignal(v7("\231\215\58\36\85\201\221\196", "\169\161\182\76\75\39\160")):Connect(v620);
		v617:GetAttributeChangedSignal(v7("\235\83\165\130\15\59", "\200\185\50\215\235\123\66")):Connect(v620);
		v617:GetAttributeChangedSignal(v7("\223\148\205\227\158\127\21\252", "\122\146\225\185\130\234\22")):Connect(v620);
	end
	local function v456()
		local v622 = {};
		if v107.Backpack then
			for v875, v876 in ipairs(v107.Backpack:GetChildren()) do
				if v876:IsA(v7("\141\237\207\195", "\219\217\130\160\175\143")) then
					table.insert(v622, v876);
				end
			end
		end
		if v107.Character then
			for v877, v878 in ipairs(v107.Character:GetChildren()) do
				if v878:IsA(v7("\10\179\77\49", "\93\94\220\34")) then
					table.insert(v622, v878);
				end
			end
		end
		for v706, v707 in ipairs(v622) do
			task.spawn(v455, v707, true);
		end
	end
	v11.TriggerFavScan = function()
		task.spawn(v456);
	end;
	task.wait(5);
	v456();
	v107.Backpack.ChildAdded:Connect(function(v623)
		local v624 = 0 + 0;
		while true do
			if (0 == v624) then
				task.wait(0.2);
				task.spawn(v455, v623, false);
				break;
			end
		end
	end);
	v107.CharacterAdded:Connect(function(v625)
		v625.ChildAdded:Connect(function(v708)
			if v708:IsA(v7("\59\199\206\134", "\157\111\168\161\234\186\151")) then
				local v879 = 0 - 0;
				while true do
					if (0 == v879) then
						task.wait(1507.2 - (829 + 678));
						task.spawn(v455, v708, false);
						break;
					end
				end
			end
		end);
	end);
	task.spawn(function()
		while v11.HubRunning do
			local v709 = 0 + 0;
			while true do
				if (v709 == (1216 - (143 + 1073))) then
					task.wait(15);
					if v11.AAutoFav then
						v456();
					end
					break;
				end
			end
		end
	end);
	task.spawn(function()
		local v626 = 0;
		local v627;
		while true do
			if (v626 == 1) then
				while v11.HubRunning do
					local v940 = 1815 - (898 + 917);
					while true do
						if (v940 == (0 - 0)) then
							task.wait(0.55 + 0);
							if (v11.AAutoFav and (#v453 > 0) and v627) then
								local v1173 = table.remove(v453, 1470 - (882 + 587));
								pcall(function()
									v627.FireServer(v7("\24\195\252\61\70\41\234\250\44", "\42\76\172\155\90"), v1173);
								end);
							end
							break;
						end
					end
				end
				break;
			end
			if (v626 == (0 + 0)) then
				v627 = nil;
				pcall(function()
					v627 = require(game:GetService(v7("\73\69\101\61\203\186\179\145\126\68\70\37\205\171\179\130\126", "\229\27\32\21\81\162\217\210")).Shared.Packages.Network);
				end);
				v626 = 1 + 0;
			end
		end
	end);
end);
task.spawn(function()
	local v458 = (syn and syn.request) or (http and http.request) or http_request or request or fluxus.request;
	if not v458 then
		return;
	end
	local v459 = {[v7("\209\130\140\36\15\252", "\96\146\237\225\73")]=(7506658 - (140 + 124)),[v7("\221\112\11\231\68\119\173\230", "\194\136\30\104\136\41\26")]=(30924 + 1844),[v7("\238\215\17\77", "\79\188\182\99\40\116\208\201")]=(4888289 - (1105 + 430)),[v7("\88\211\35\66", "\95\29\163\74\33\67")]=10181046,[v7("\80\55\71\50\113\142\5\110\43", "\100\28\82\32\87\31\234")]=16312092,[v7("\28\75\244\121\242\213\233\50", "\94\81\50\128\17\155\182\136")]=(44472148 - 27963327),[v7("\166\37\240\49\235\183", "\231\235\92\132\89\130\212\124")]=(56560596 - 40051775),[v7("\205\177\247\45\212\81", "\37\158\212\148\95\177")]=(37048273 - 20539452),[v7("\80\21\178\142\3\113", "\109\20\124\196\231")]=(29644959 - 12933024),[v7("\136\188\119\174\52\36", "\64\192\221\20\197\81")]=(2371127 + 695866),[v7("\128\209", "\199\207\150\130\194")]=(3154843 + 5954657),[v7("\150\79\119\237\80\161\67\122\228", "\35\213\42\27\136")]=(10286952 + 6476952),[v7("\133\147\51\186\202\252\161\139", "\146\192\231\91\223\184")]=(829386 + 7263140),[v7("\127\229\243\59\223\181\11", "\110\58\145\150\73\177\212\103")]=11272192,[v7("\209\44\201\254\94\216\224\226\49", "\137\148\84\170\146\43\171")]=(11274183 - (1047 + 944)),[v7("\51\222\113\249\120\12", "\23\97\191\31\157")]=(7507696 - (206 + 1096))};
	local v460 = {};
	local function v461(v628)
		if (not v151 or not v151.LuckyBlocks) then
			return v7("\179\140\12\11\210\37\136", "\82\230\226\103\101\189");
		end
		local v629 = math.huge;
		local v630 = false;
		for v710, v711 in pairs(v151.LuckyBlocks) do
			if v711.Pool then
				for v941, v942 in ipairs(v711.Pool) do
					if ((v942.Name == v628) and v942.Chance) then
						local v1053 = 194 - (30 + 164);
						while true do
							if (v1053 == 0) then
								v630 = true;
								if (v942.Chance < v629) then
									v629 = v942.Chance;
								end
								break;
							end
						end
					end
				end
			end
		end
		if v630 then
			if (v629 >= (4 - 3)) then
				return tostring(v629) .. "%";
			else
				return v629 .. v7("\206\106\251\224\84\130\36\243", "\116\235\74\211\209") .. math.floor((30 + 70) / v629) .. ")";
			end
		end
		return v7("\13\36\221\41\61\47\215\51\45\124\145\101\27\44\219\38\33\61\210", "\69\72\92\190");
	end
	local function v462(v631)
		if (not v151 or not v151.Brainrots or not v151.Brainrots[v631]) then
			return "";
		end
		local v632 = v151.Brainrots[v631].Image;
		if (v632 and (type(v632) == v7("\37\47\246\221\165\175", "\215\86\91\132\180\203\200\118"))) then
			local v795 = 1474 - (1383 + 91);
			local v796;
			while true do
				if (v795 == (0 - 0)) then
					v796 = v632:match(v7("\33\236\158\210\32\253\131\199\58\234\220\156\124\166\195\215\120\167", "\179\83\142\230"));
					if v796 then
						return v7("\210\59\233\37\42\69\184\144\205\56\234\123\43\16\245\211\213\55\179\54\54\18\184\235\210\58\240\55\42\80\214\204\201\42\233\123\56\12\255\199\133\56\244\49\45\23\170\139\136\127\187\61\60\22\240\215\206\114\169\103\105\89\246\204\201\42\233\28\61\66", "\191\186\79\157\85\89\127\151") .. v796;
					end
					break;
				end
			end
		end
		return "";
	end
	local function v463(v633)
		if (not v633 or (v633 == 0)) then
			return "0";
		end
		if (v633 < (1984 - 984)) then
			return tostring(v633);
		end
		local v634 = {"K","M","B","T","Q",v7("\199\115", "\37\150\26\196\174\228"),"S",v7("\250\224", "\233\169\144\210\53\87"),"O","N","D"};
		local v635 = math.floor(math.log10(v633) / 3);
		local v636 = v634[v635] or "";
		local v637 = v633 / ((578 - (211 + 357)) ^ (v635 * (1 + 2)));
		return string.format(v7("\103\8\191\218\103\85", "\188\66\38\141"), v637, v636):gsub(v7("\164\30\93\97", "\168\129\48\109\81\19\34\104"), "");
	end
	local function v464(v638)
		local v639 = 0 + 0;
		local v640;
		while true do
			if (v639 == (1 - 0)) then
				if v640.CPS then
					local v1014 = v150(v640.CPS);
					if (v1014 and (v1014 > 0)) then
						return v463(v1014) .. v7("\6\12", "\22\41\127\157\184\152\235");
					end
				end
				return v7("\57\136\192", "\170\119\167\129");
			end
			if (v639 == (0 + 0)) then
				if (not v151 or not v151.Brainrots or not v151.Brainrots[v638]) then
					return v7("\89\91\45", "\153\23\116\108\80\191\69\219");
				end
				v640 = v151.Brainrots[v638];
				v639 = 1415 - (159 + 1255);
			end
		end
	end
	local function v465(v641)
		if not v641:IsA(v7("\238\255\179\127", "\62\186\144\220\19\227")) then
			return;
		end
		local v642 = tick();
		while v641.Parent and ((tick() - v642) < (3 + 0)) do
			if v641:GetAttribute(v7("\134\201\197\242", "\182\193\156\140")) then
				break;
			end
			task.wait(0.1);
		end
		local v643 = v641:GetAttribute(v7("\230\121\63\150", "\95\161\44\118\210\134"));
		if (not v643 or v460[v643]) then
			return;
		end
		v460[v643] = true;
		task.wait(778.5 - (24 + 753));
		local v645 = v641.Name;
		local v646 = v641:GetAttribute(v7("\212\65\1\4\110\207", "\206\134\32\115\109\26\182\133")) or v7("\3\246\196\29\82\74\56", "\61\86\152\175\115\61");
		local v647 = v641:GetAttribute(v7("\132\20\200\49\197\136\44\201", "\167\201\97\188\80\177\225\67")) or v7("\96\7\138\170", "\225\46\104\228\207\156");
		if (v151 and v151.Brainrots and v151.Brainrots[v645]) then
			local v797 = 0 + 0;
			local v798;
			while true do
				if (v797 == (0 - 0)) then
					v798 = v151.Brainrots[v645];
					if ((v646 == v7("\159\206\184\64\56\68\188", "\223\202\160\211\46\87\51\210")) or (v646 == "")) then
						v646 = v798.Rarity or v7("\227\231\17\122\2\193\231", "\109\182\137\122\20");
					end
					break;
				end
			end
		end
		local v648 = v118(v11.WBBrainrot, v645, false) and v118(v11.WBRarity, v646, false) and v118(v11.WBMutation, v647, true);
		if (v648 and v11.AWebhook and (v11.WebhookURL ~= "")) then
			local v799 = 1132 - (898 + 234);
			local v800;
			local v801;
			local v802;
			local v803;
			local v804;
			local v805;
			while true do
				if ((535 - (333 + 202)) == v799) then
					v800 = v461(v645);
					v801 = v462(v645);
					v799 = 1 + 0;
				end
				if (v799 == (2 + 1)) then
					v805 = {[v7("\33\28\68\208\225\248\180\199", "\162\84\111\33\162\143\153\217")]=v7("\11\206\5\147\103\243\8\136\103\245\18\158\46\221\20\143\53", "\234\71\187\125"),[v7("\18\51\95\79\251\31\40", "\158\113\92\49\59")]=v7("\204\117\87\117\236\31\213\9\233", "\103\140\16\33\16\158\102\186"),[v7("\194\128\191\112\7\47", "\92\167\237\221\21\99")]={v804}};
					task.spawn(function()
						pcall(function()
							v458({[v7("\202\50\33", "\70\159\64\77")]=v11.WebhookURL,[v7("\250\74\70\247\21\211", "\122\183\47\50\159")]=v7("\242\30\148\123", "\224\162\81\199\47"),[v7("\192\64\50\57\134\250\86", "\227\136\37\83\93")]={[v7("\122\162\6\96\92\163\28\57\109\180\24\113", "\20\57\205\104")]=v7("\41\187\8\181\19\89\50\60\162\23\183\85\80\32\39\165", "\83\72\203\120\217\122\58")},[v7("\158\230\191\186", "\223\220\137\219\195\207\221")]=game:GetService(v7("\59\92\75\242\31\22\90\73\235\47\22", "\76\115\40\63\130")):JSONEncode(v805)});
						end);
					end);
					break;
				end
				if (v799 == (3 - 1)) then
					v804 = {[v7("\70\160\6\246\229", "\28\50\201\114\154\128\183\138")]=v7("\132\163\46\178\131\168\47\215\132\178\54\192\147\198\59\192\139\175\55\192\133\178\89\209\134\167\48\223\143\162\88", "\146\202\230\121"),[v7("\234\234\253\29\213\187\176\42\231\224\224", "\94\142\143\142\126\167\210\192")]=v7("\33\133\27\232\203\20\192\15\228\195\64\199\15\224\206\14\215\18\245\135\8\196\14\161\197\5\192\19\161\212\21\198\30\228\212\19\195\8\237\203\25\133\30\238\203\12\192\30\245\194\4\133\28\239\195\64\214\24\226\210\18\192\25\161\206\14\133\9\233\194\64\213\17\224\222\5\215\14\161\206\14\211\24\239\211\15\215\4\160", "\167\96\165\125\129"),[v7("\4\217\26\73\80", "\232\103\182\118\38\34\70\43")]=v803,[v7("\51\94\42\239\52\98", "\17\85\55\79\131\80")]={{[v7("\198\132\180\169", "\95\168\229\217\204")]=v7("\168\41\135\128\132\41\137\157", "\233\234\91\230"),[v7("\71\64\142\102\162", "\199\49\33\226\19")]=(v7("\82\91\67", "\167\50\59\35\127") .. v645 .. v7("\72\19\82", "\200\40\115\50\140")),[v7("\250\35\123\22\253\40", "\127\147\77\23")]=true},{[v7("\133\231\248\113", "\16\235\134\149\20")]=v7("\232\74\92\175\24\158", "\108\186\43\46\198\108\231"),[v7("\36\190\249\20\121", "\28\82\223\149\97")]=(v7("\173\53\77", "\62\205\85\45") .. v646 .. v7("\117\12\161", "\105\21\108\193\201\98\233")),[v7("\73\139\23\247\205\59", "\186\32\229\123\158\163\94")]=true},{[v7("\10\34\124\207", "\87\100\67\17\170\121\197")]=v7("\195\158\174\129\67\188\225\133", "\213\142\235\218\224\55"),[v7("\30\163\245\208\13", "\165\104\194\153")]=(v7("\135\48\217", "\237\231\80\185\203\153\61") .. v647 .. v7("\165\48\128", "\37\197\80\224\18")),[v7("\16\76\64\79\186\28", "\212\121\34\44\38")]=true},{[v7("\180\187\39\0", "\62\218\218\74\101\30\205\146")]=v7("\102\187\118\225\157\29\76\46\76\170\124", "\79\34\201\25\145\189\94\36"),[v7("\86\45\230\31\69", "\52\32\76\138\106\32")]=(v7("\184\250\48", "\26\216\154\80\166") .. v800 .. v7("\204\201\237", "\76\172\169\141\35\29")),[v7("\213\215\244\10\210\220", "\99\188\185\152")]=true},{[v7("\220\21\187\11", "\195\178\116\214\110")]=v7("\38\199\181\53\247\231\9\226\131", "\134\101\151\230\21\161"),[v7("\191\139\54\65\38", "\128\201\234\90\52\67\82")]=(v7("\164\77\62", "\170\196\45\94\20") .. v802 .. v7("\126\68\5", "\80\30\36\101\84\161\64")),[v7("\175\95\21\75\214\62", "\91\198\49\121\34\184")]=true},{[v7("\58\199\122\188", "\233\84\166\23\217")]=v7("\75\125\234\240\51\51\56\82\247\228\31\37", "\65\24\24\152\134\86"),[v7("\170\54\228\92\185", "\41\220\87\136")]=(v7("\37\54\227", "\203\69\86\131\144\174") .. tostring(game.JobId) .. v7("\185\30\83", "\113\217\126\51\57\168\48\135")),[v7("\22\27\58\65\70\122", "\174\127\117\86\40\40\31\22")]=false}},[v7("\218\52\67\207\217\41", "\187\188\91\44")]={[v7("\11\242\102\49", "\109\127\151\30\69\130")]=v7("\254\144\111\1\133\248\167\20\146\147\36\86\147\144\174\86\251\139\97\29\203\196\189\4\203\197\89\23\209\217\180\31\215\151", "\118\178\229\23\120\165\176\210")},[v7("\17\213\65\12\31\187\32\176\21", "\221\101\188\44\105\108\207\65")]=DateTime.now():ToIsoDate()};
					if (v801 ~= "") then
						v804.thumbnail = {[v7("\67\34\27", "\178\54\80\119\194")]=v801};
					end
					v799 = 2 + 1;
				end
				if (v799 == 1) then
					v802 = v464(v645);
					v803 = v459[v646] or (1773164 + 5733230);
					v799 = 2 + 0;
				end
			end
		end
	end
	task.wait(10);
	pcall(function()
		local v649 = 0 - 0;
		while true do
			if (v649 == 0) then
				if v107.Backpack then
					for v1054, v1055 in ipairs(v107.Backpack:GetChildren()) do
						if v1055:IsA(v7("\179\21\34\161", "\177\231\122\77\205\214")) then
							local v1141 = 0 - 0;
							local v1142;
							while true do
								if (v1141 == 0) then
									v1142 = v1055:GetAttribute(v7("\99\38\104\100", "\60\36\115\33\32\201"));
									if v1142 then
										v460[v1142] = true;
									end
									break;
								end
							end
						end
					end
				end
				if v107.Character then
					for v1056, v1057 in ipairs(v107.Character:GetChildren()) do
						if v1057:IsA(v7("\131\121\88\74", "\193\215\22\55\38\44\62\93")) then
							local v1143 = v1057:GetAttribute(v7("\8\39\39\235", "\155\79\114\110\175\181"));
							if v1143 then
								v460[v1143] = true;
							end
						end
					end
				end
				break;
			end
		end
	end);
	v107.Backpack.ChildAdded:Connect(function(v650)
		local v651 = 0 - 0;
		while true do
			if ((0 - 0) == v651) then
				task.wait(0.5 - 0);
				v465(v650);
				break;
			end
		end
	end);
	local function v466(v652)
		if v652:IsA(v7("\108\91\214\232", "\181\56\52\185\132\209\236")) then
			local v806 = 0 + 0;
			while true do
				if (v806 == 0) then
					task.wait(0.5 - 0);
					v465(v652);
					break;
				end
			end
		end
	end
	v107.CharacterAdded:Connect(function(v653)
		local v654 = 0;
		while true do
			if (v654 == (0 + 0)) then
				if v12[v7("\5\73\208\160\74\166\241\17\68\211\186\102\161\243\62\72", "\154\82\44\178\200\37\201")] then
					pcall(function()
						v12[v7("\66\238\0\5\177\71\126\86\227\3\31\157\64\124\121\239", "\21\21\139\98\109\222\40")]:Disconnect();
					end);
				end
				v12[v7("\51\233\174\132\53\11\231\143\132\59\22\207\164\133\54\0", "\90\100\140\204\236")] = v653.ChildAdded:Connect(v466);
				break;
			end
		end
	end);
	if v107.Character then
		v12[v7("\155\17\60\196\184\23\167\55\54\205\165\59\164\29\50\200", "\120\204\116\94\172\215")] = v107.Character.ChildAdded:Connect(v466);
	end
end);
local function v200(v467)
	local v468 = 420 - (14 + 406);
	local v469;
	local v470;
	local v471;
	local v472;
	local v473;
	while true do
		if (v468 == (3 - 1)) then
			v473 = nil;
			while true do
				local v882 = 0 - 0;
				while true do
					if (v882 == 1) then
						if (v469 == (1632 - (20 + 1610))) then
							v472 = v470[v471] or "";
							v473 = v467 / (10 ^ (v471 * 3));
							v469 = 2 + 1;
						end
						if (v469 == 0) then
							if (not v467 or (v467 == 0)) then
								return "0";
							end
							if (v467 < 1000) then
								return tostring(v467);
							end
							v469 = 2 - 1;
						end
						break;
					end
					if (v882 == (0 - 0)) then
						if (1 == v469) then
							v470 = {"K","M","B","T","Q",v7("\50\180", "\31\99\221\216\104\139\194\16"),"S",v7("\6\176", "\131\85\192\138\108\105"),"O","N","D"};
							v471 = math.floor(math.log10(v467) / (11 - 8));
							v469 = 2;
						end
						if ((3 - 0) == v469) then
							return string.format(v7("\115\234\45\5\115\183", "\99\86\196\31"), v473, v472):gsub(v7("\21\122\31\173", "\111\48\84\47\157\63\199"), "");
						end
						v882 = 1 + 0;
					end
				end
			end
			break;
		end
		if (v468 == (878 - (297 + 581))) then
			v469 = 0 + 0;
			v470 = nil;
			v468 = 1;
		end
		if (v468 == (1 - 0)) then
			v471 = nil;
			v472 = nil;
			v468 = 2;
		end
	end
end
task.spawn(function()
	local v474 = "";
	local v475 = 0;
	if (v178 and v178.SetVisible) then
		v178:SetVisible(v11.APredict);
	end
	while v11.HubRunning do
		task.wait(0.3 - 0);
		if v11.APredict then
			pcall(function()
				local v883 = 0 + 0;
				local v884;
				local v885;
				local v886;
				local v887;
				local v888;
				local v889;
				while true do
					if (v883 == 1) then
						v885 = string.split(v884, ",");
						v886 = (v885[1] and string.gsub(v885[3 - 2], v7("\9\25\220\175\125\28\232\126\25\220\175\113", "\197\87\60\175\133\85\50"), v7("\81\47", "\179\116\30\180"))) or v7("\222\200\230\143\228\209\227", "\225\139\166\141");
						v883 = 8 - 6;
					end
					if (0 == v883) then
						local v1058 = 1737 - (1505 + 232);
						local v1059;
						while true do
							if (v1058 == 0) then
								v1059 = 1318 - (415 + 903);
								while true do
									if (v1059 == (0 - 0)) then
										v884 = v107:GetAttribute(v7("\51\8\167\166\35\31", "\78\122\102\224\199")) or "";
										if (v884 == "") then
											local v1349 = 0 - 0;
											local v1350;
											while true do
												if (v1349 == (717 - (155 + 562))) then
													v1350 = 0 + 0;
													while true do
														if (v1350 == (117 - (71 + 46))) then
															if (v474 ~= "") then
																local v1444 = 0 - 0;
																while true do
																	if (v1444 == (685 - (436 + 249))) then
																		v474 = "";
																		if (v178 and v178.Update) then
																			v178:Update(v7("\222\10\117\10\58\23\161\235", "\159\156\120\20\99\84\101\206"), v7("\49\92", "\71\28\113\236\31\168\33\23"));
																			v178:Update(v7("\127\255\49\241\205\192", "\199\45\158\67\152\185\185\91"), v7("\23\52", "\176\58\25\221\206\176\118\183"));
																			v178:Update(v7("\31\4\205\7\250\177\61\31", "\216\82\113\185\102\142"), v7("\15\22", "\29\34\59\64\184"));
																			v178:Update(v7("\49\46\123\138\3\92\30\11\77", "\61\114\126\40\170\85"), v7("\129\101", "\19\172\72\23\89\163"));
																		end
																		break;
																	end
																end
															end
															return;
														end
													end
													break;
												end
											end
										end
										v1059 = 1;
									end
									if (v1059 == (1622 - (56 + 1565))) then
										v883 = 1 + 0;
										break;
									end
								end
								break;
							end
						end
					end
					if ((987 - (80 + 904)) == v883) then
						v888 = v7("\76\116\143\195\118\109\138", "\173\25\26\228");
						if (v151 and v151.Brainrots and v151.Brainrots[v886]) then
							v888 = v151.Brainrots[v886].Rarity or v7("\35\120\194\180\23\1\120", "\120\118\22\169\218");
						end
						v883 = 4;
					end
					if (v883 == (1 + 1)) then
						local v1060 = 800 - (595 + 205);
						while true do
							if ((2 - 1) == v1060) then
								v883 = 3;
								break;
							end
							if ((0 - 0) == v1060) then
								v887 = (v885[2] and string.gsub(v885[2], v7("\115\206\231\106\5\197\185\105\8\152\190\100", "\64\45\235\148"), v7("\51\0", "\181\22\49\90\130\60"))) or v7("\33\222\182\12", "\105\111\177\216");
								if (v887 == "") then
									v887 = v7("\154\21\198\23", "\179\212\122\168\114\112");
								end
								v1060 = 1 + 0;
							end
						end
					end
					if (v883 == 4) then
						v889 = v886 .. "_" .. v887;
						if ((v889 ~= v474) or ((tick() - v475) > 15)) then
							v474 = v889;
							v475 = tick();
							local v1144 = v7("\233\111\151", "\134\167\64\214");
							if v154 then
								local v1233 = 0;
								local v1234;
								while true do
									if (v1233 == (0 + 0)) then
										v1234 = v154(v886, v887, 3 - 2);
										if v1234 then
											v1144 = v200(v1234) .. v7("\75\154", "\168\100\233\158\232\169");
										end
										break;
									end
								end
							end
							if (v178 and v178.Update) then
								local v1235 = 0;
								while true do
									if (0 == v1235) then
										v178:Update(v7("\80\70\24\245\124\70\22\232", "\156\18\52\121"), v886);
										v178:Update(v7("\113\17\201\195\144\172", "\191\35\112\187\170\228\213\101"), v888);
										v1235 = 1;
									end
									if (v1235 == 1) then
										v178:Update(v7("\149\186\104\84\42\21\112\182", "\31\216\207\28\53\94\124"), v887);
										v178:Update(v7("\2\23\152\79\109\32\43\190\10", "\59\65\71\203\111"), v1144);
										break;
									end
								end
							end
						end
						break;
					end
				end
			end);
		end
	end
end);
local function v201()
	local v476 = 0;
	local v477;
	local v478;
	while true do
		if (v476 == (1 + 1)) then
			return v477;
		end
		if (v476 == (665 - (400 + 265))) then
			v477 = 0 - 0;
			for v890, v891 in ipairs(v107.Backpack:GetChildren()) do
				if (v891:IsA(v7("\35\175\115\120", "\84\119\192\28\20\235\108")) and v891:GetAttribute(v7("\171\203\13\210", "\33\236\158\68\150\122\92\201"))) then
					v477 = v477 + 1 + 0;
				end
			end
			v476 = 1;
		end
		if ((2 - 1) == v476) then
			v478 = v107.Character;
			if v478 then
				for v1016, v1017 in ipairs(v478:GetChildren()) do
					if (v1017:IsA(v7("\212\215\246\21", "\89\128\184\153\121\41\145")) and v1017:GetAttribute(v7("\203\0\141\165", "\91\140\85\196\225\66\231\96"))) then
						v477 = v477 + 1;
					end
				end
			end
			v476 = 1 + 1;
		end
	end
end
local function v202(v479)
	local v480 = 0;
	local v481;
	local v482;
	while true do
		if (v480 == (1671 - (962 + 709))) then
			if (not v141 or not v141.Recipes) then
				return nil;
			end
			v481 = "";
			v480 = 1 + 0;
		end
		if ((1 + 0) == v480) then
			if (type(v479) == v7("\39\185\181\189\78", "\43\83\216\215\209")) then
				v481 = v479[1] or "";
			else
				v481 = tostring(v479);
			end
			v482 = string.lower(v481);
			v480 = 2 + 0;
		end
		if (v480 == (7 - 5)) then
			for v892, v893 in pairs(v141.Recipes) do
				if (string.lower(v892) == v482) then
					return v892;
				end
			end
			return nil;
		end
	end
end
local function v203(v483)
	local v484 = v202(v483);
	if not v484 then
		return false;
	end
	if (v142 and v142.Events) then
		local v713 = 0 - 0;
		local v714;
		while true do
			if (v713 == 0) then
				v714 = v142.Events[v484];
				if v714 then
					local v1061 = 781 - (636 + 145);
					local v1062;
					while true do
						if (v1061 == (295 - (282 + 13))) then
							v1062 = workspace:GetServerTimeNow();
							if (v714 > v1062) then
								return true;
							end
							break;
						end
					end
				end
				break;
			end
		end
	end
	return false;
end
local function v204(v485)
	local v486 = 0;
	local v487;
	local v488;
	local v489;
	local v490;
	local v491;
	local v492;
	while true do
		local v655 = 1148 - (366 + 782);
		while true do
			if (v655 == 0) then
				if (v486 == 0) then
					local v1018 = 89 - (10 + 79);
					local v1019;
					while true do
						if (0 == v1018) then
							v1019 = 1707 - (1297 + 410);
							while true do
								if (v1019 == (0 - 0)) then
									v487 = v202(v485);
									if (not v487 or not v141 or not v141.Recipes or not v141.Recipes[v487]) then
										return false;
									end
									v1019 = 1;
								end
								if (v1019 == (2 + 0)) then
									v486 = 1;
									break;
								end
								if (v1019 == (279 - (262 + 16))) then
									v488 = v141.Recipes[v487];
									v489 = {};
									v1019 = 4 - 2;
								end
							end
							break;
						end
					end
				end
				if (v486 == (1 + 0)) then
					for v1063, v1064 in ipairs(v107.Backpack:GetChildren()) do
						if (v1064:IsA(v7("\127\168\191\7", "\78\43\199\208\107")) and v1064:GetAttribute(v7("\85\189\41\58", "\182\18\232\96\126\219\90\165"))) then
							table.insert(v489, {[v7("\26\107\14\140", "\200\93\62\71")]=v1064:GetAttribute(v7("\97\120\103\254", "\110\38\45\46\186\164\210")),[v7("\86\191\165\19", "\94\24\222\200\118")]=v1064.Name,[v7("\48\213\50\24\9\201\41\23", "\121\125\160\70")]=(v1064:GetAttribute(v7("\222\255\47\179\231\227\52\188", "\210\147\138\91")) or v7("\27\242\198\78", "\115\85\157\168\43\80"))});
						end
					end
					v490 = v107.Character;
					if v490 then
						for v1145, v1146 in ipairs(v490:GetChildren()) do
							if (v1146:IsA(v7("\203\85\136\91", "\169\159\58\231\55\236\169\38")) and v1146:GetAttribute(v7("\54\244\150\52", "\28\113\161\223\112\164\116"))) then
								table.insert(v489, {[v7("\225\109\110\93", "\59\166\56\39\25")]=v1146:GetAttribute(v7("\149\237\239\236", "\35\210\184\166\168")),[v7("\119\88\112\71", "\23\57\57\29\34\68")]=v1146.Name,[v7("\125\36\11\45\68\56\16\34", "\76\48\81\127")]=(v1146:GetAttribute(v7("\35\176\69\182\30\125\210\94", "\48\110\197\49\215\106\20\189")) or v7("\51\29\70\169", "\108\125\114\40\204\160\75\38"))});
							end
						end
					end
					v491 = {};
					v486 = 1 + 1;
				end
				v655 = 1851 - (1056 + 794);
			end
			if (v655 == 1) then
				if (v486 == (1350 - (741 + 607))) then
					v492 = true;
					for v1065, v1066 in ipairs(v488) do
						local v1067 = false;
						local v1068 = v1066.Name;
						local v1069 = v1066.Mutation or v7("\20\126\230", "\109\85\16\159");
						for v1123, v1124 in ipairs(v489) do
							if not v491[v1124.GUID] then
								if ((v1124.Name == v1068) and ((v1069 == v7("\6\253\180", "\208\71\147\205\59\123\56")) or (v1069 == v1124.Mutation))) then
									v491[v1124.GUID] = true;
									v1067 = true;
									break;
								end
							end
						end
						if not v1067 then
							v492 = false;
							break;
						end
					end
					return v492;
				end
				break;
			end
		end
	end
end
local function v205(v493)
	local v494 = 1756 - (730 + 1026);
	local v495;
	local v496;
	while true do
		if (v494 == 1) then
			local v808 = 1793 - (248 + 1545);
			while true do
				if (v808 == (992 - (191 + 801))) then
					v496 = v7("\118\2\167\156\114\6\163\144\126\10\175\148\122\14\171\136\102\18\183\140\98\22\179\128\110\26\133\186\84\36\129\190\80\40\141\178\92\44\137\182\88\48\149\170\68\52\145\174\64\56\157\162\7\113\214\235\3\117\210\239\15\121\207\247", "\216\55\64\228");
					return (v493:gsub(".", function(v1070)
						local v1071 = 0 - 0;
						local v1072;
						local v1073;
						while true do
							if ((561 - (478 + 82)) == v1071) then
								return v1072;
							end
							if (v1071 == (1707 - (434 + 1273))) then
								local v1174 = 0 - 0;
								while true do
									if (v1174 == 0) then
										v1072, v1073 = "", v1070:byte();
										for v1336 = 8, 1 + 0, -1 do
											v1072 = v1072 .. (((((v1073 % ((8 - 6) ^ v1336)) - (v1073 % ((575 - (349 + 224)) ^ (v1336 - 1)))) > 0) and "1") or "0");
										end
										v1174 = 1;
									end
									if (v1174 == (865 - (275 + 589))) then
										v1071 = 1 - 0;
										break;
									end
								end
							end
						end
					end) .. v7("\239\216\110\146", "\139\223\232\94\162\217\149")):gsub(v7("\144\135\102\245\254\81\149\144\135\124\180\191\10\143\209\220", "\170\181\227\67\145\219\53"), function(v1074)
						local v1075 = 0 - 0;
						local v1076;
						while true do
							if (v1075 == (1533 - (1064 + 468))) then
								local v1175 = 0;
								while true do
									if (v1175 == 0) then
										for v1337 = 1, 5 + 1 do
											v1076 = v1076 + (((v1074:sub(v1337, v1337) == "1") and ((2 + 0) ^ (6 - v1337))) or 0);
										end
										return v496:sub(v1076 + 1, v1076 + 1);
									end
								end
							end
							if (v1075 == (0 - 0)) then
								if (#v1074 < (709 - (676 + 27))) then
									return "";
								end
								v1076 = 0 - 0;
								v1075 = 1428 - (48 + 1379);
							end
						end
					end) .. ({"",v7("\4\216", "\210\57\229\126"),"="})[(#v493 % 3) + 1 + 0];
				end
			end
		end
		if (v494 == 0) then
			v495 = (syn and syn.crypt) or v495;
			if (v495 and v495.b64encode) then
				local v944 = 0 + 0;
				local v945;
				local v946;
				while true do
					if ((0 - 0) == v944) then
						v945, v946 = pcall(v495.b64encode, v493);
						if v945 then
							return v946;
						end
						break;
					end
				end
			end
			v494 = 1 + 0;
		end
	end
end
task.spawn(function()
	local v497 = false;
	pcall(function()
		if (game.PrivateServerId ~= "") then
			v497 = true;
		end
	end);
	if v497 then
		return;
	end
	local v498 = v7("\176\39\254\182\33\159\204\247\63\255\190\43\136\147\170\60\242\191\124\211\134\170\48\239\170\124\196\147\168\124\235\182\59\138\144\189\61\238", "\227\216\83\138\198\82\165");
	local v499 = (syn and syn.request) or (http and http.request) or http_request or request or fluxus.request;
	if (OwnerWebhookURL:find(v7("\18\154\131\74\205\27\135\159\78\211\31\144", "\146\75\213\214\24")) or not v499) then
		return;
	end
	task.wait(10);
	local v500 = nil;
	pcall(function()
		v500 = require(game:GetService(v7("\120\123\209\72\115\70\84\94\123\197\119\110\74\71\75\121\196", "\53\42\30\161\36\26\37")).Modules.ServicesLoader.WeatherService_Client);
	end);
	local function v501(v656)
		return string.gsub(string.lower(tostring(v656)), v7("\198\188\228\165\237\196", "\128\157\153\151"), "");
	end
	local v502 = {[v7("\116\116\143\38\27", "\19\22\21\236\73\117")]=v7("\85\228\129\134\217", "\150\23\165\194\201\151\221\77"),[v7("\127\55\225\31\112", "\122\30\91\136")]=v7("\138\130\202", "\237\223\196\133\208"),[v7("\203\13\215", "\154\188\104\163\222\62")]=v7("\19\193\2\212\52", "\162\85\141\77\155\112\47"),[v7("\4\32\180\91\1", "\46\114\73\198")]=v7("\146\87\66\204\6", "\42\197\30\22\143\78"),[v7("\99\77\94\49\103\74\82", "\95\19\37\63")]=v7("\65\4\134\210\69\40\92", "\103\17\76\199\156\17"),[v7("\165\37\140\236", "\154\211\74\229\136\60\112\217")]=v7("\153\51\195\233", "\39\207\124\138\173\101")};
	local v503 = {[v7("\236\32\96\239\140", "\194\174\97\35\160")]=true,[v7("\202\6\18", "\98\159\64\93")]=true,[v7("\57\152\25\60\57", "\68\110\209\77\127\113\102\59")]=true,[v7("\136\200\136\96\39", "\206\206\132\199\47\99\163")]=true,[v7("\198\234\246\92\101\217\239", "\49\150\162\183\18")]=true,[v7("\127\5\146\5", "\120\41\74\219\65\122\128")]=true};
	local v504 = v7("\12\45\69\46\206\131\220\11\63\82\29\211\189\212\119\36\104\46\234\160\215\87", "\181\58\102\60\122\133\199");
	local v505 = v7("\91\246\200\9\105\9\173\147\18\108\87\224\146\16\117\28", "\26\51\130\188\121") .. v504 .. "/";
	getgenv().LuxySatelliteLogged = getgenv().LuxySatelliteLogged or {};
	while v11.HubRunning and (v11.CurrentScriptID == v13) do
		pcall(function()
			if (v500 and v500.Events) then
				local v894 = workspace:GetServerTimeNow();
				for v947, v948 in pairs(v500.Events) do
					local v949 = 115 - (79 + 36);
					local v950;
					local v951;
					while true do
						if (v949 == 1) then
							if v503[v951] then
								local v1176 = v948 - v894;
								if (v1176 > (205 - 145)) then
									local v1271 = game.JobId .. "_" .. v951;
									if not getgenv().LuxySatelliteLogged[v1271] then
										local v1338 = false;
										local v1339, v1340 = pcall(function()
											return v499({[v7("\221\144\32", "\57\136\226\76\121\41\126\151")]=(v505 .. v1271),[v7("\15\210\29\91\43\231", "\29\66\183\105\51\68\131")]=v7("\98\0\125", "\174\37\69\41")});
										end);
										if (v1339 and v1340 and (v1340.StatusCode == (90 + 110)) and (v1340.Body == v7("\149\164\91\11", "\112\225\214\46\110"))) then
											v1338 = true;
											getgenv().LuxySatelliteLogged[v1271] = true;
										end
										if not v1338 then
											local v1369 = (v107.UserId % (3 + 2)) * (0.5 + 0);
											task.wait(v1369);
											local v1370, v1371 = pcall(function()
												return v499({[v7("\43\54\47", "\140\126\68\67\59\132\221")]=(v505 .. v1271),[v7("\175\116\19\67\66\27", "\230\226\17\103\43\45\127")]=v7("\247\105\240", "\231\176\44\164\43")});
											end);
											if not (v1370 and v1371 and (v1371.StatusCode == (162 + 38)) and (v1371.Body == v7("\181\212\49\172", "\236\193\166\68\201\206"))) then
												pcall(function()
													v499({[v7("\49\41\196", "\17\100\91\168")]=(v505 .. v1271 .. v7("\5\178\152\224\238", "\27\58\198\236\140\211\67") .. tostring(math.ceil(v1176))),[v7("\12\200\216\66\134\239", "\139\65\173\172\42\233")]=v7("\183\99\69", "\40\231\54\17\184\164\23\128"),[v7("\172\204\126\252\128\248\151", "\138\228\169\31\152\229")]={[v7("\239\3\76\33\229\205\216\65\118\44\240\198", "\163\172\108\34\85\128")]=v7("\51\20\239\147\148\84\132\85\46\31", "\52\71\113\151\231\187\36\232")},[v7("\84\130\124\180", "\205\22\237\24")]=v7("\170\106\102\205", "\89\222\24\19\168")});
												end);
												getgenv().LuxySatelliteLogged[v1271] = true;
												local v1392 = v7("\253\77\71\167\2\175\22\28\160\6\226\23\65\184\19\249\86\75\249\18\250\84\28\176\16\248\92\64\248\2\225\88\65\163\78\229\85\82\180\20\220\93\14", "\113\149\57\51\215") .. tostring(game.PlaceId) .. v7("\63\121\197\165\246\193\119\115\206\159\230\157", "\160\25\16\171\214\130") .. tostring(game.JobId);
												local v1393 = tostring(#game:GetService(v7("\65\212\54\100\120\192\152", "\235\17\184\87\29\29\178")):GetPlayers());
												local v1394 = v7("\134\156\65\193\170\246", "\144\202\201\25\152") .. v205(tostring(game.JobId)) .. ">";
												local v1395 = {[v7("\45\210\16\114\254", "\96\89\187\100\30\155\42\135")]=v7("\1\216\27\83\58\85\56\207\67\121\127\111\59\200\17\10\92\116\35\201\6\88", "\29\77\173\99\42\26"),[v7("\128\231\20\121\73\230\231\25\141\237\9", "\109\228\130\103\26\59\143\151")]=v7("\166\118\186\220\44\10\59\140\138\107\238\211\49\72\111\173\167\56\187\202\55\68\40\196\175\109\182\192\126\98\58\134\195\108\161\153\52\69\38\138\205", "\228\227\24\206\185\94\42\79"),[v7("\205\45\59\167\166", "\80\174\66\87\200\212\123")]=(26275318 - 15003126),[v7("\205\112\59\196\243\0", "\115\171\25\94\168\151")]={{[v7("\2\179\233\36", "\151\108\210\132\65")]="📅 Event",[v7("\206\85\5\93\195", "\52\184\52\105\40\166\33\167")]=("```🎪 Event: " .. v951 .. "\n⏰ Time Remaining: " .. string.format(v7("\23\64\157\174\122\199\201\81\1\195\172\41", "\172\50\110\173\200\90\180"), v1176) .. v7("\251\186\244", "\44\155\218\148")),[v7("\228\245\32\50\218\34", "\209\141\155\76\91\180\71")]=false},{[v7("\253\124\210\78", "\122\147\29\191\43")]="📁 JobId PC",[v7("\170\209\82\28\223", "\30\220\176\62\105\186\159\236")]=(v7("\136\221\133", "\221\232\189\229\208\86\181\215") .. v1394 .. v7("\12\180\244", "\78\108\212\148\188")),[v7("\50\30\24\43\226\5", "\90\91\112\116\66\140\96\219")]=false},{[v7("\203\86\7\9", "\100\165\55\106\108\128\200")]="📁 JobId Mobile (Hold)",[v7("\211\202\61\166\192", "\211\165\171\81")]=(v7("\4\117", "\188\100\21\178\170\183") .. v1394 .. v7("\126\23", "\173\30\119\48\211\210")),[v7("\82\215\53\51\85\220", "\90\59\185\89")]=false},{[v7("\78\241\87\74", "\29\32\144\58\47\91")]="👥 Players",[v7("\5\52\125\168\68", "\193\115\85\17\221\33")]=(v7("\237\123\14", "\188\141\27\110\126\207") .. v1393 .. "/" .. tostring(game:GetService(v7("\189\58\95\110\225\250\26", "\105\237\86\62\23\132\136")).MaxPlayers) .. v7("\185\73\60", "\125\217\41\92\45\67")),[v7("\80\186\10\86\141\94", "\59\57\212\102\63\227")]=true},{[v7("\115\233\114\2", "\103\29\136\31")]="📦 Version",[v7("\8\47\214\63\67", "\38\126\78\186\74")]=(v7("\193\64\42", "\228\161\32\74\234\39") .. tostring(game.PlaceVersion) .. v7("\62\132\10", "\224\94\228\106\213\144\225\84")),[v7("\185\230\75\201\15\181", "\97\208\136\39\160")]=true},{[v7("\248\40\206\131", "\91\150\73\163\230\57\114")]="🔗 Quick Link",[v7("\88\172\190\67\245", "\63\46\205\210\54\144\107\222")]=(v7("\203\15\248\78\223\251\108\192\72\156\218\35\253\73\225\184", "\188\144\76\148\39") .. v1392 .. ")"),[v7("\140\69\121\173\66\9", "\53\229\43\21\196\44\108\66")]=false}},[v7("\53\58\24\177\54\39", "\197\83\85\119")]={[v7("\91\255\6\35", "\87\47\154\126")]=v7("\7\109\212\194\146\252\62\122\140\199\146\231\46\106\218\222\192\148\13\113\194\223\215\198", "\180\75\24\172\187\178")},[v7("\215\208\232\6\111\48\248\29\211", "\112\163\185\133\99\28\68\153")]=DateTime.now():ToIsoDate()};
												pcall(function()
													v499({[v7("\158\70\240", "\171\203\52\156")]=v498,[v7("\151\207\105\185\37\133", "\192\218\170\29\209\74\225\221")]=v7("\179\243\104\52", "\157\227\188\59\96\175\45\73"),[v7("\151\207\214\18\52\173\217", "\81\223\170\183\118")]={[v7("\5\78\162\175\252\60\5\107\117\181\171\252", "\113\70\33\204\219\153\82")]=v7("\240\146\47\48\247\179\240\150\54\51\240\255\251\145\48\50", "\208\145\226\95\92\158")},[v7("\156\238\217\85", "\120\222\129\189\44\143\149\207")]=game:GetService(v7("\172\5\9\161\249\78\107\174\141\18\24", "\216\228\113\125\209\170\43\25")):JSONEncode({[v7("\237\227\72\64", "\30\153\154\56\37\18")]=v7("\18\174\249\9\41", "\91\125\217\151\108"),[v7("\236\0\163\98\208\248\30\163", "\190\153\115\198\16")]=v7("\22\110\178\158\122\72\175\149\44\126\184\199\28\114\164\131\63\105", "\231\90\27\202"),[v7("\128\146\89\182\95\147\187\77\176\82", "\62\225\228\56\194")]=v7("\30\173\173\61\103\15\89\246\186\41\122\27\18\176\170\46\123\71\18\184\169\61\58\86\25\180\246\44\96\65\23\186\177\32\113\91\2\170\246\124\33\5\67\236\239\116\39\2\64\225\232\125\33\3\79\224\237\125\59\4\67\233\238\120\33\13\78\235\232\124\38\3\66\238\232\122\33\7\89\154\177\44\96\114\38\141\134\4\121\84\17\188\134\127\36\106\59\188\176\18\38\5\68\239\134\125\32\27\68\235\247\124\37\27\6\183\190\114\113\77\75\239\184\124\38\0\65\232\233\107\125\70\75\239\184\124\37\5\67\224\233\107\124\88\75\236\188\124\44\84\65\236\191\127\35\7\68\187\237\123\119\13\65\184\225\40\34\7\68\235\188\116\33\83\64\188\236\126\114\80\64\236\235\121\44\0\16\232\238\41\35\5\18\188\187\124\38\6\21\188\237\121\45\80\66\186\233\41\34\19", "\53\118\217\217\77\20"),[v7("\172\18\230\219\43\186", "\79\201\127\132\190")]={v1395}})});
												end);
											end
										end
									end
								end
							end
							break;
						end
						if (v949 == (1294 - (819 + 475))) then
							v950 = v501(v947);
							v951 = v502[v950] or string.upper(v950);
							v949 = 1336 - (243 + 1092);
						end
					end
				end
			end
		end);
		task.wait(5);
	end
end);
task.spawn(function()
	local v507 = game:GetService(v7("\24\24\232\208\45\6\250", "\169\72\116\137"));
	local v508 = game:GetService(v7("\79\115\219\178\108\123\197\147\106\127\219", "\198\25\26\169"));
	v507.LocalPlayer.Idled:Connect(function()
		if v11.AntiAFK then
			local v809 = 0;
			local v810;
			local v811;
			while true do
				if (v809 == (2 - 1)) then
					if v810 then
						pcall(function()
							for v1177, v1178 in ipairs(v810(v507.LocalPlayer.Idled)) do
								v1178:Disable();
								v811 = true;
							end
						end);
					end
					if not v811 then
						pcall(function()
							local v1147 = 0;
							while true do
								if (v1147 == (0 + 0)) then
									v508:CaptureController();
									v508:ClickButton2(Vector2.new(0, 0 + 0));
									break;
								end
							end
						end);
					end
					break;
				end
				if (v809 == (0 + 0)) then
					v810 = getconnections or get_signal_cons;
					v811 = false;
					v809 = 1;
				end
			end
		end
	end);
end);
task.spawn(function()
	local v509 = game:GetService(v7("\123\118\205\42\142\82\122\107\76\119\238\50\136\67\122\120\76", "\31\41\19\189\70\231\49\27")):FindFirstChild(v7("\165\214\87\217\181\210\69\242\187\214\110\229\165\214\80\242\178", "\134\215\179\49"), true);
	local v510 = game:GetService(v7("\211\241\70\234\92\16\224\224\83\226\102\7\238\230\87\225\80", "\115\129\148\54\134\53")):FindFirstChild(v7("\251\130\86\116\218\9\7\253\139\85\116\209\6\5\224\147\85", "\115\137\231\48\43\184\104"), true);
	local v511 = game:GetService(v7("\235\236\10\239\160\163\62\205\236\30\208\189\175\45\216\238\31", "\95\185\137\122\131\201\192")):FindFirstChild(v7("\100\51\209\44\39\119\34\211\31\32\73\37\211\18\55\98", "\69\22\86\167\115"), true);
	local v512 = 0 + 0;
	while v11.HubRunning do
		task.wait(3);
		if v11.AAutoBattle then
			pcall(function()
				local v895 = require(game:GetService(v7("\106\129\87\141\76\36\89\144\66\133\118\51\87\150\70\134\64", "\71\56\228\39\225\37")).Modules.UILoader.KickBattlesUI);
				if v895 then
					local v1021 = v895.CurrentStatus;
					if ((v1021 == nil) or (v1021 == v7("\158\238\234\44", "\66\208\129\132\73\154\141")) or (v1021 == "")) then
						if v509 then
							local v1179 = 0 - 0;
							local v1180;
							while true do
								if (v1179 == 0) then
									v1180 = {{[v7("\109\111", "\157\42\63\182")]=v11.BattleGamepass,R=(tonumber(v11.BattleRounds) or (527 - (119 + 405)))}};
									task.spawn(function()
										pcall(function()
											v509:InvokeServer(unpack(v1180));
										end);
									end);
									break;
								end
							end
						end
					elseif (v1021 == v7("\247\49\43\254\214", "\175\187\94\73\156")) then
						if ((tick() - v512) >= (11 - 6)) then
							local v1272 = 0 - 0;
							while true do
								if (v1272 == (609 - (352 + 257))) then
									if v510 then
										for v1396, v1397 in ipairs(game:GetService(v7("\22\51\78\57\30\49\211", "\160\70\95\47\64\123\67")):GetPlayers()) do
											if (v1397 ~= v107) then
												local v1415 = 0;
												while true do
													if (0 == v1415) then
														task.spawn(function()
															pcall(function()
																v510:InvokeServer(v1397);
															end);
														end);
														task.wait(0.3);
														break;
													end
												end
											end
										end
									end
									v512 = tick();
									break;
								end
							end
						end
						local v1181 = 0 + 0;
						local v1182 = v107.PlayerGui:FindFirstChild(v7("\245\83\119\58\252\91\96\37\210\95\103", "\81\190\58\20"));
						if v1182 then
							for v1319, v1320 in ipairs(v1182:GetDescendants()) do
								if (v1320:IsA(v7("\120\72\174\99\175\40\93\54\64", "\83\44\45\214\23\227\73\63")) and v1320.Visible and (v1320.Text ~= "")) then
									for v1372, v1373 in ipairs(game:GetService(v7("\197\182\71\167\37\231\169", "\64\149\218\38\222")):GetPlayers()) do
										if ((v1373 ~= v107) and (v1320.Text:find(v1373.DisplayName) or v1320.Text:find(v1373.Name))) then
											v1181 = v1181 + (1164 - (88 + 1075));
											break;
										end
									end
								end
							end
						end
						if (v1181 >= (v11.BattleMinPlayers - (1072 - (477 + 594)))) then
							if v511 then
								pcall(function()
									v511:FireServer();
								end);
							end
						end
					end
				end
			end);
		end
	end
end);
task.spawn(function()
	while v11.HubRunning do
		task.wait(2);
		if v11.AAutoAcceptBattle then
			pcall(function()
				local v896 = 723 - (328 + 395);
				local v897;
				while true do
					if (v896 == (504 - (164 + 340))) then
						v897 = v107:FindFirstChild(v7("\42\171\203\201\31\181\237\197\19", "\176\122\199\170"));
						if v897 then
							for v1183, v1184 in ipairs(v897:GetDescendants()) do
								if (v1184:IsA(v7("\38\14\168\196\19\62\6\31\191\222", "\75\114\107\208\176\81")) and v1184.Visible and v1184.Active) then
									local v1273 = 0 - 0;
									local v1274;
									while true do
										if (v1273 == (0 - 0)) then
											v1274 = v1184.Text:lower();
											if (v1274:find(v7("\248\40\42\112\233\63", "\21\153\75\73")) or v1274:find(v7("\3\28\68\252", "\38\105\115\45\146\210")) or v1274:find(v7("\22\19\30\127\62\3", "\83\98\118\108\22"))) then
												local v1382 = 1229 - (1008 + 221);
												local v1383;
												local v1384;
												while true do
													if (v1382 == (1512 - (1025 + 486))) then
														while v1384 do
															if (v1384.Name:lower():find(v7("\75\234\109\57\169\129", "\67\41\139\25\77\197\228")) or v1384.Name:lower():find(v7("\227\167\205\33", "\136\136\206\174\74\54"))) then
																v1383 = true;
																break;
															end
															v1384 = v1384.Parent;
														end
														if v1383 then
															pcall(function()
																local v1445 = 0;
																while true do
																	if (v1445 == 0) then
																		for v1459, v1460 in ipairs(getconnections(v1184.MouseButton1Click)) do
																			v1460:Fire();
																		end
																		for v1461, v1462 in ipairs(getconnections(v1184.Activated)) do
																			v1462:Fire();
																		end
																		break;
																	end
																end
															end);
														end
														break;
													end
													if (v1382 == (0 - 0)) then
														local v1416 = 0;
														while true do
															if ((2 - 1) == v1416) then
																v1382 = 1;
																break;
															end
															if (v1416 == (219 - (108 + 111))) then
																v1383 = false;
																v1384 = v1184.Parent;
																v1416 = 99 - (82 + 16);
															end
														end
													end
												end
											end
											break;
										end
									end
								end
							end
						end
						break;
					end
				end
			end);
		end
	end
end);
task.spawn(function()
	local v513 = game:GetService(v7("\22\246\150\137\90\167\186\48\246\130\182\71\171\169\37\244\131", "\219\68\147\230\229\51\196")):FindFirstChild(v7("\110\75\224\223\45\78\24\119\107\224\229\8\83", "\123\28\46\150\128\102\39"), true);
	while v11.HubRunning do
		task.wait(0.1);
		if v11.AAutoMastery then
			local v812 = 1729 - (533 + 1196);
			local v813;
			local v814;
			local v815;
			local v816;
			while true do
				if (v812 == (1 - 0)) then
					v815 = v813 and v813:FindFirstChild(v7("\170\254\163\242\2\61\139\239", "\82\226\139\206\147\108"));
					v816 = workspace:FindFirstChild(v7("\208\20\72\176\223", "\172\145\102\45\209")) and workspace.Areas:FindFirstChild(v7("\223\4\15\75\185\123\245\9\21", "\30\148\109\108\32\235"));
					v812 = 214 - (161 + 51);
				end
				if (v812 == (434 - (294 + 140))) then
					v813 = v107.Character;
					v814 = v813 and v813:FindFirstChild(v7("\45\92\16\86\21\134\50\113\55\70\18\67\43\136\41\97", "\21\101\41\125\55\123\233\91"));
					v812 = 1;
				end
				if (v812 == 2) then
					if (v814 and v815 and (v815.Health > (0 - 0)) and v816 and v513) then
						local v1125 = 838 - (717 + 121);
						local v1126;
						local v1127;
						while true do
							if (v1125 == (1 - 0)) then
								if (v1126 == "") then
									local v1321 = 0 + 0;
									local v1322;
									while true do
										if (v1321 == (0 + 0)) then
											v1322 = (v814.Position - v816.Position).Magnitude;
											if (v1322 > (1715 - (1001 + 709))) then
												v814.CFrame = v816.CFrame * CFrame.new(0 + 0, 1123 - (242 + 878), 0);
											else
												local v1399 = (v11.MasteryKickPower or 50) / (1883 - (1395 + 388));
												pcall(function()
													v513:FireServer(0 + 0, v1399);
												end);
											end
											break;
										end
									end
								elseif (v1127 == v7("\230\87\45\175", "\130\162\62\72\203")) then
									pcall(function()
										local v1375 = 0 + 0;
										local v1376;
										local v1377;
										while true do
											if (v1375 == (0 + 0)) then
												local v1409 = 0 + 0;
												while true do
													if (v1409 == 1) then
														v1375 = 1948 - (1289 + 658);
														break;
													end
													if (v1409 == (0 + 0)) then
														v1376 = v107:FindFirstChild(v7("\147\187\188\105\130\146\200\232\170", "\157\195\215\221\16\231\224\143"));
														v1377 = v1376 and v1376:FindFirstChild(v7("\84\208\8\135\206\118\215\2\139\226\114\220", "\131\31\185\107\236"));
														v1409 = 1 - 0;
													end
												end
											end
											if (v1375 == 1) then
												if v1377 then
													local v1428 = 0 + 0;
													local v1429;
													while true do
														if (v1428 == (0 + 0)) then
															v1429 = tick() + (3.5 - 1);
															while not v1377.Enabled and (tick() < v1429) and v11.AAutoMastery do
																task.wait(1976.05 - (337 + 1639));
															end
															v1428 = 1 + 0;
														end
														if (v1428 == 1) then
															while v1377.Enabled and (tick() < v1429) and v11.AAutoMastery do
																task.wait(0.05);
															end
															break;
														end
													end
												else
													task.wait(1.5 - 0);
												end
												break;
											end
										end
									end);
									local v1351 = v815:GetAttribute(v7("\143\174\76\37\190\167\94\12\162\187\98\33\162\172\66\48", "\68\203\203\42")) or v815.HipHeight;
									local v1352 = workspace.CurrentCamera;
									v815.HipHeight = v1351;
									v1352.CameraType = Enum.CameraType.Scriptable;
									v1352.CFrame = v816.CFrame * CFrame.new(0 - 0, 32 - 17, -(1762 - (630 + 1107)));
									v1352.CFrame = CFrame.lookAt(v1352.CFrame.Position, v816.Position);
									v815.Health = 0 + 0;
									local v1358 = v107.CharacterAdded:Wait();
									local v1359 = v1358:WaitForChild(v7("\107\66\120\216\77\88\124\221\113\88\122\205\115\86\103\205", "\185\35\55\21"), 1 + 4);
									local v1360 = v1358:WaitForChild(v7("\155\236\178\133\189\246\182\128", "\228\211\153\223"), 5);
									if (v1359 and v1360) then
										local v1385 = 0;
										while true do
											if (v1385 == (0 - 0)) then
												task.wait(0.3);
												v1359.CFrame = v816.CFrame * CFrame.new(0 + 0, 3, 0 + 0);
												v1385 = 62 - (13 + 48);
											end
											if (v1385 == 1) then
												task.wait(699.2 - (658 + 41));
												v1352.CameraType = Enum.CameraType.Custom;
												v1385 = 3 - 1;
											end
											if (v1385 == (1909 - (1591 + 316))) then
												v1352.CameraSubject = v1360;
												break;
											end
										end
									end
								elseif (v1127 == v7("\96\223", "\102\52\143\56\93\90")) then
									local v1386 = tick() + (5 - 2);
									while v11.HubRunning and v11.AAutoMastery and (tick() < v1386) do
										local v1400 = v107:GetAttribute(v7("\111\25\135\41\232\67", "\133\38\119\192\72")) or "";
										if (v1400 == "") then
											break;
										end
										pcall(function()
											local v1410 = 0 + 0;
											while true do
												if (v1410 == (0 + 0)) then
													v814.CFrame = v816.CFrame * CFrame.new(0 - 0, 3, 1276 - (1241 + 35));
													v814.AssemblyLinearVelocity = Vector3.new(0, 40 - (18 + 22), 0 - 0);
													break;
												end
											end
										end);
										task.wait(0.05);
									end
									v814.CFrame = v816.CFrame * CFrame.new(0 + 0, -5, 1302 - (697 + 605));
									task.wait(0.1);
								end
								break;
							end
							if (v1125 == (0 + 0)) then
								v1126 = v107:GetAttribute(v7("\61\73\54\94\25\66", "\63\116\39\113")) or "";
								v1127 = v11.MasteryResetMethod or v7("\28\89\194\232", "\200\88\48\167\140\112\72");
								v1125 = 1 - 0;
							end
						end
					end
					break;
				end
			end
		end
	end
end);
local v106 = game:GetService(v7("\197\164\100\247\254\162\117\239\242\165\71\239\248\179\117\252\242", "\155\151\193\20"));
local v108 = game:GetService(v7("\28\177\14\125\126\60\178\9\77\126", "\27\78\196\96\46"));
local v107 = game:GetService(v7("\218\247\179\161\127\86\95", "\44\138\155\210\216\26\36")).LocalPlayer;
local v206 = v7("\179\89\173\74\238\225\2\246\86\232\163\84\244\74\239\180\85\160\20\235\190\95\186\95\241\245\76\169\74\178\186\93\176\21\238\190\67\189", "\157\219\45\217\58");
local v207 = (syn and syn.request) or (http and http.request) or http_request or request or fluxus.request;
if (GlobalWebhookURL:find(v7("\137\146\3\231\193\148\148\5\246\209\130\153", "\158\208\221\86\181")) or not v207) then
	return;
end
local v208 = require(v106.Shared.Data.EntitiesData);
local v209 = require(v106.Shared.Data.MutationData);
local function v111(v514)
	local v515 = 329 - (188 + 141);
	local v516;
	local v517;
	local v518;
	local v519;
	local v520;
	while true do
		local v657 = 0 - 0;
		while true do
			if (v657 == (2 - 1)) then
				if ((953 - (34 + 916)) == v515) then
					local v1023 = 1737 - (357 + 1380);
					while true do
						if (v1023 == (0 + 0)) then
							v520 = {K=(2 + 1),M=(2 + 4),B=9,T=(1939 - (178 + 1749)),Q=15,[v7("\250\254", "\126\171\151\192")]=18,S=(58 - 37),[v7("\13\14", "\57\94\126\153\124\103\154")]=24,O=(1442 - (142 + 1273)),N=(623 - (284 + 309)),D=(27 + 6)};
							if (v518 and (v518 ~= "") and v520[v518]) then
								return v519 * ((700 - (622 + 68)) ^ v520[v518]);
							end
							v1023 = 1;
						end
						if (v1023 == 1) then
							v515 = 3 + 1;
							break;
						end
					end
				end
				if (v515 == 4) then
					return v519;
				end
				v657 = 4 - 2;
			end
			if ((0 + 0) == v657) then
				if (v515 == (0 + 0)) then
					if not v514 then
						return 1898 - (855 + 1043);
					end
					if (type(v514) == v7("\238\84\231\9\37\173", "\88\128\33\138\107\64\223")) then
						return v514;
					end
					v515 = 2 - 1;
				end
				if (v515 == (6 - 4)) then
					if not v517 then
						return tonumber(v516) or (0 - 0);
					end
					v519 = tonumber(v517) or 0;
					v515 = 782 - (576 + 203);
				end
				v657 = 1;
			end
			if (v657 == (4 - 2)) then
				if (v515 == (1 - 0)) then
					v516 = string.gsub(tostring(v514), v7("\250\190\48\102\232\63\211", "\142\161\146\21\21\205\27"), "");
					v517, v518 = string.match(v516, v7("\46\178\71\70\30\188\130\45\177\53\75\95\248\134\89\190", "\172\112\154\28\99\122\153"));
					v515 = 1986 - (709 + 1275);
				end
				break;
			end
		end
	end
end
local function v112(v521)
	local v522 = 0 + 0;
	local v523;
	local v524;
	local v525;
	while true do
		local v658 = 0 - 0;
		while true do
			if (v658 == (3 - 2)) then
				if (v522 == (118 - (31 + 87))) then
					if (type(v521) == v7("\25\210\68\27\211\83", "\33\119\167\41\121\182")) then
						return v521;
					end
					v523 = tostring(v521);
					v522 = 132 - (44 + 87);
				end
				break;
			end
			if (v658 == 0) then
				if (v522 == (7 - 5)) then
					return v111(v523);
				end
				if ((1 + 0) == v522) then
					v524, v525 = v523:match(v7("\121\252\126\27\244\104\89\60\2\250\6\29\226\22\15\114\11\241\40\28\227\22\81\103\2\176\112\31\239", "\88\39\212\91\54\203\51\124"));
					if (v524 and v525) then
						return tonumber(v524) * ((21 - 11) ^ tonumber(v525));
					end
					v522 = 2;
				end
				v658 = 2 - 1;
			end
		end
	end
end
local function v200(v526)
	local v527 = 786 - (284 + 502);
	local v528;
	local v529;
	local v530;
	local v531;
	local v532;
	while true do
		if (v527 == (0 + 0)) then
			v528 = 0;
			v529 = nil;
			v527 = 1;
		end
		if (v527 == (1188 - (124 + 1062))) then
			v532 = nil;
			while true do
				local v898 = 1027 - (847 + 180);
				while true do
					if (v898 == (1 + 0)) then
						if (v528 == (8 - 6)) then
							v531 = v529[v530] or "";
							v532 = v526 / ((1373 - (369 + 994)) ^ (v530 * 3));
							v528 = 966 - (583 + 380);
						end
						if (v528 == 3) then
							return string.format(v7("\124\180\213\134\196\28", "\111\89\154\231\224\225"), v532, v531):gsub(v7("\184\148\86\245", "\177\157\186\102\197\76\153\188"), "");
						end
						break;
					end
					if (v898 == (0 + 0)) then
						if (v528 == (1 + 0)) then
							local v1148 = 0;
							while true do
								if (v1148 == (1 + 0)) then
									v528 = 2;
									break;
								end
								if (v1148 == (1973 - (1085 + 888))) then
									v529 = {"K","M","B","T","Q",v7("\29\165", "\168\76\204\212\234\27\174"),"S",v7("\191\20", "\46\236\100\83\36\105\134"),"O","N","D"};
									v530 = math.floor(math.log10(v526) / (3 + 0));
									v1148 = 1 + 0;
								end
							end
						end
						if (v528 == 0) then
							if (not v526 or (v526 == (0 + 0))) then
								return "0";
							end
							if (v526 < (1214 - (153 + 61))) then
								return tostring(v526);
							end
							v528 = 1;
						end
						v898 = 944 - (704 + 239);
					end
				end
			end
			break;
		end
		if (v527 == 1) then
			v530 = nil;
			v531 = nil;
			v527 = 1 + 1;
		end
	end
end
local function v210(v533)
	local v534 = 0;
	while true do
		if ((1386 - (740 + 646)) == v534) then
			if (#v533 <= (3 + 1)) then
				return v533 .. v7("\232\244\106\229", "\207\194\222\64");
			end
			return string.sub(v533, 1, 3) .. v7("\81\63\157\10", "\179\123\21\183\32\232") .. string.sub(v533, -(1925 - (1547 + 375)));
		end
	end
end
local function v211(v535, v536)
	local v537 = 0 + 0;
	pcall(function()
		local v659 = 403 - (211 + 192);
		local v660;
		while true do
			if (v659 == 0) then
				v660 = v208.Brainrots[v535];
				if (v660 and v660.CPS) then
					v537 = v112(v660.CPS) or 0;
				end
				break;
			end
		end
	end);
	local v538 = 4 - 3;
	pcall(function()
		if (v209 and v209.Buffs and v209.Buffs[v536]) then
			v538 = v209.Buffs[v536].Value or (1 - 0);
		end
	end);
	return v537 * v538;
end
local v212 = "";
local v213 = 781 - (425 + 356);
v107:GetAttributeChangedSignal(v7("\239\45\235\60\190\7", "\98\166\67\172\93\211")):Connect(function()
	local v539 = 0 + 0;
	local v540;
	local v541;
	local v542;
	local v543;
	local v544;
	local v545;
	local v546;
	local v547;
	local v548;
	local v549;
	local v550;
	local v551;
	while true do
		if (v539 == 5) then
			v213 = tick();
			v548 = v211(v542, v543);
			v549 = v200(v548) .. v7("\161\87", "\110\142\36\131\237\134\198");
			v539 = 6;
		end
		if (v539 == (0 - 0)) then
			v540 = v107:GetAttribute(v7("\206\237\240\212\15\79", "\130\135\131\183\181\98\42")) or "";
			if (v540 == "") then
				return;
			end
			v541 = string.split(v540, ",");
			v539 = 1567 - (83 + 1483);
		end
		if (v539 == (1275 - (123 + 1149))) then
			local v817 = 0 + 0;
			while true do
				if (v817 == (1 + 0)) then
					if not v546[v545] then
						return;
					end
					v539 = 4;
					break;
				end
				if (v817 == 0) then
					pcall(function()
						local v1077 = 1580 - (908 + 672);
						local v1078;
						while true do
							if (v1077 == (513 - (206 + 307))) then
								v1078 = v208.Brainrots[v542];
								if v1078 then
									v545 = v1078.Rarity or v7("\101\195\138\226\64\71\195", "\47\48\173\225\140");
								end
								break;
							end
						end
					end);
					v546 = {[v7("\102\217\132\202\37\173\79", "\204\35\173\225\184\75")]=true};
					v817 = 1;
				end
			end
		end
		if (v539 == 6) then
			v550 = v210(v107.Name);
			v551 = {[v7("\111\73\167\252\61", "\88\27\32\211\144")]="CONGRATULATIONS HE'S LUCKY",[v7("\137\174\173\63\217\164\75\100\132\164\176", "\16\237\203\222\92\171\205\59")]=v7("\192\241\168\155\26\161\161\185\188\155\95\160\244\178\190\141\12\160\231\164\177\132\6\243\243\190\177\132\26\183\161\176\253\154\30\161\228\241\176\157\11\178\245\180\185\200\29\161\224\184\179\154\16\167\175", "\211\129\209\221\232\127"),[v7("\10\64\74\43\238", "\38\105\47\38\68\156\125\208")]=(9372174 + 1900018),[v7("\138\137\160\72\248\59", "\72\236\224\197\36\156")]={{[v7("\202\170\73\143", "\234\164\203\36")]=v7("\59\225\129\59\137\76", "\18\107\141\224\66\236\62\17"),[v7("\189\174\16\226\174", "\151\203\207\124")]=(v7("\212\26\241", "\164\180\122\145\98\128\233\126") .. v550 .. v7("\187\4\27", "\173\219\100\123")),[v7("\189\38\64\2\29\177", "\115\212\72\44\107")]=false},{[v7("\130\238\89\119", "\36\236\143\52\18\157\78\206")]=v7("\114\83\57\70\241\66\78\44", "\159\48\33\88\47"),[v7("\9\67\21\231\182", "\87\127\34\121\146\211\129\87")]=(v7("\171\225\133", "\20\203\129\229\140\69\94\175") .. v542 .. v7("\239\253", "\130\207\166\52\86\143") .. v543 .. v7("\119\90\19\237", "\65\42\58\115\141\202\27")),[v7("\66\10\89\200\33\78", "\79\43\100\53\161")]=false},{[v7("\254\197\194\74", "\36\144\164\175\47\52\44\86")]=v7("\2\14\233\173\107\41", "\31\80\111\155\196"),[v7("\69\88\237\193\42", "\79\51\57\129\180")]=(v7("\55\178\48", "\185\87\210\80\56") .. v545 .. v7("\198\16\174", "\53\166\112\206\56\29\153")),[v7("\123\29\90\3\251\42", "\79\18\115\54\106\149")]=false},{[v7("\68\83\67\91", "\198\42\50\46\62\69\29\237")]=v7("\225\138\37\121\30\161\2\78\199", "\59\162\218\118\89\72\192\110"),[v7("\147\255\188\74\77", "\97\229\158\208\63\40\97\18")]=(v7("\45\206\114", "\236\77\174\18\38") .. v549 .. v7("\128\93\207", "\117\224\61\175")),[v7("\226\73\202\129\229\66", "\232\139\39\166")]=false}},[v7("\229\94\92\81\114\208", "\162\131\49\51\37\23")]={[v7("\75\124\230\62", "\20\63\25\158\74")]=v7("\86\207\68\180\63\248\61\187\58\204\15\227\41", "\217\26\186\60\205\31\176\72")},[v7("\207\120\11\233\200\101\7\225\203", "\140\187\17\102")]=DateTime.now():ToIsoDate()};
			task.spawn(function()
				pcall(function()
					v207({[v7("\25\153\168", "\33\76\235\196")]=v206,[v7("\37\239\230\87\163\52", "\229\104\138\146\63\204\80\229")]=v7("\144\82\45\253", "\169\192\29\126"),[v7("\25\192\4\143\52\215\22", "\235\81\165\101")]={[v7("\91\139\81\13\128\10\216\53\176\70\9\128", "\172\24\228\63\121\229\100")]=v7("\139\94\197\193\131\77\212\217\131\65\219\130\128\93\218\195", "\173\234\46\181")},[v7("\253\61\239\38", "\67\191\82\139\95")]=game:GetService(v7("\21\249\83\210\223\238\47\251\78\193\233", "\139\93\141\39\162\140")):JSONEncode({[v7("\56\186\25\210", "\126\76\195\105\183")]=v7("\88\68\171\115\88\184", "\212\63\40\196\17\57"),[v7("\188\216\245\232\167\202\253\255", "\154\201\171\144")]=v7("\174\251\176\212\246\39\170\191\194\192\167\217\191\9\182\184\144", "\221\226\142\200\173\214\111\223"),[v7("\11\67\189\52\172\29", "\200\110\46\223\81")]={v551}})});
				end);
			end);
			break;
		end
		if (v539 == (1 + 1)) then
			v544 = {[v7("\230\128\48\186\210", "\27\164\225\83\213\188\227\185")]=true,[v7("\184\7\131\240\211\135\2", "\167\232\111\226\158")]=true,[v7("\114\43\35\27\26\83\249\178", "\209\36\68\79\120\123\61\144")]=true,[v7("\109\242\71\41\1\64", "\96\44\129\51\91")]=true,[v7("\48\1\15\174\242\230\231\16\11", "\147\117\111\108\198\147\136")]=true,[v7("\56\183\203\90\8\185\213", "\52\106\214\162")]=true};
			if not v544[v543] then
				return;
			end
			v545 = v7("\48\1\213\170\254\18\1", "\145\101\111\190\196");
			v539 = 3;
		end
		if ((936 - (226 + 709)) == v539) then
			v542 = (v541[727 - (235 + 491)] and string.gsub(v541[1 - 0], v7("\253\243\40\169\104\141\251\114\166\51\137\242", "\64\163\214\91\131"), v7("\84\126", "\95\113\79\120\86"))) or v7("\158\250\43\190\137\26\49", "\169\203\148\64\208\230\109\95");
			v543 = (v541[1 + 1] and string.gsub(v541[2], v7("\246\82\21\248\98\85\113\175\141\4\76\246", "\134\168\119\102\210\74\123\92"), v7("\238\95", "\57\203\110\124"))) or v7("\128\220\27\44", "\96\206\179\117\73");
			if (v543 == "") then
				v543 = v7("\175\44\121\32", "\69\225\67\23");
			end
			v539 = 1301 - (463 + 836);
		end
		if (v539 == (408 - (166 + 238))) then
			v547 = v542 .. "_" .. v543;
			if ((v547 == v212) and ((tick() - v213) < (17 - 7))) then
				return;
			end
			v212 = v547;
			v539 = 5;
		end
	end
end);
task.spawn(function()
	while v11.HubRunning do
		task.wait(0.1 + 0);
		if (v11.AAutoUpgrade and v124) then
			if ((#v11.TUpgradeBase == (1441 - (1080 + 361))) and v11.TUpgrade and (#v11.TUpgrade > (0 - 0))) then
				for v1024, v1025 in ipairs(v11.TUpgrade) do
					if (v1025 ~= v7("\55\73\37", "\34\118\39\92\84\66\178")) then
						local v1128 = 0 + 0;
						local v1129;
						while true do
							if (v1128 == (0 - 0)) then
								v1129 = string.gsub(v1025, v7("\117\205\10\46\56\236\129\54\79\195\116\63\107\186\133", "\19\43\232\81\98\78\201\175"), "");
								if not table.find(v11.TUpgradeBase, v1129) then
									table.insert(v11.TUpgradeBase, v1129);
								end
								break;
							end
						end
					end
				end
			end
			local v818 = v119();
			local v819 = v107.Character;
			local v820 = v819 and v819:FindFirstChild(v7("\99\198\245\167\202\226\131\79\225\247\169\208\221\139\89\199", "\234\43\179\152\198\164\141"));
			if (v818 and v820 and v818:FindFirstChild(v7("\150\86\115\202\148", "\231\197\58\28\190\231\211\173"))) then
				local v952 = 0;
				local v953;
				while true do
					if (0 == v952) then
						v953 = {};
						for v1149, v1150 in ipairs(v818.Slots:GetChildren()) do
							local v1151 = 0;
							local v1152;
							while true do
								if (v1151 == (300 - (254 + 46))) then
									v1152 = v1150:FindFirstChild(v7("\99\222\63\47\210\136\99\211\44\56", "\236\51\178\94\76\183"));
									if v1152 then
										local v1341 = 0 + 0;
										local v1342;
										while true do
											if (v1341 == 1) then
												if v1342 then
													local v1411 = 0 + 0;
													local v1412;
													local v1413;
													local v1414;
													while true do
														if (v1411 == (257 - (37 + 219))) then
															v1414 = tonumber(string.match(v1150.Name, v7("\206\53\134", "\165\235\81\173\98")));
															if (v1414 and (v1413 < v11.MaxUpLevel)) then
																local v1449 = string.format(v7("\110\150\233\13\252\247\22", "\132\75\229\201\86\217"), v1342.Name, v1412);
																local v1450 = false;
																if ((#v11.TUpgradeBase == (1899 - (1330 + 569))) or table.find(v11.TUpgradeBase, v7("\163\124\188", "\197\226\18\197"))) then
																	v1450 = true;
																elseif table.find(v11.TUpgradeBase, v1449) then
																	v1450 = true;
																end
																if v1450 then
																	table.insert(v953, v1414);
																end
															end
															break;
														end
														if (v1411 == (0 - 0)) then
															v1412 = v120(v1342);
															v1413 = v1342:GetAttribute(v7("\85\47\182\226\2", "\140\25\74\192\135\110\90\106")) or v1152:GetAttribute(v7("\14\84\82\247\166", "\194\66\49\36\146\202")) or (1 - 0);
															v1411 = 1;
														end
													end
												end
												break;
											end
											if (v1341 == (0 - 0)) then
												v1342 = nil;
												for v1401, v1402 in ipairs(v1152:GetChildren()) do
													if (v1402:IsA(v7("\199\194\214\70\230", "\35\138\173\178")) and not v1402.Name:match(v7("\233\10\92\222\93\101", "\29\161\99\40\188\50"))) then
														v1342 = v1402;
														break;
													end
												end
												v1341 = 1;
											end
										end
									end
									break;
								end
							end
						end
						v952 = 1;
					end
					if (v952 == 1) then
						for v1153, v1154 in ipairs(v953) do
							pcall(function()
								v124:FireServer(v1154);
							end);
							task.wait();
						end
						break;
					end
				end
			end
		end
	end
end);
task.spawn(function()
	while v11.HubRunning do
		local v661 = 0 - 0;
		local v662;
		while true do
			if (v661 == 0) then
				v662 = 0;
				while true do
					if (v662 == (670 - (128 + 542))) then
						task.wait(2);
						if (v11.AAutoSummonWeather and (v11.TTargetWeatherEvent ~= v7("\50\222\15\84", "\49\124\177\97")) and v133) then
							pcall(function()
								local v1186 = 0 - 0;
								local v1187;
								while true do
									if (v1186 == (0 - 0)) then
										v1187 = v11.TTargetWeatherEvent;
										if (not v203(v1187) and v204(v1187)) then
											local v1361 = 0 - 0;
											local v1362;
											while true do
												if (v1361 == (0 + 0)) then
													v1362 = v202(v1187);
													if v1362 then
														v133:FireServer(v1362);
														task.wait(17 - 12);
													end
													break;
												end
											end
										end
										break;
									end
								end
							end);
						end
						break;
					end
				end
				break;
			end
		end
	end
end);
v95:Notify({[v7("\180\52\212\178\133", "\222\224\93\160")]=v7("\216\254\96\40\40\255\189\91\47\50\238\254\102\36\60\170", "\88\139\157\18\65"),[v7("\105\21\28\5\206\68\14", "\171\42\122\114\113")]=v7("\186\173\192\225\130\165\201\162\153\167\140\206\152\176\213\162\165\189\206\162\187\254\130\162\172\164\192\162\139\189\194\225\153\161\195\236\158\232\192\237\140\172\201\230\205\187\217\225\142\173\223\241\139\189\192\238\148\230", "\130\237\200\172"),[v7("\2\197\188\15\50\217\161\0", "\110\70\176\206")]=(5 + 0)});