Labs = Labs or {};

function Labs.CAID()
	-- settings
	if UnitClass("player") ~= "Mage" then return end


	enableGCD = true
	enableCast = true
	enableMageArmorBorder = true -- border and gcdbar are colored based on mage armor, not the settings below
	enablePowerBar = true
	width = 80
	height = 55
	gridGapV = 5
	gridGapH = 5
	blendType = "BLEND"
	bgColor = Media.color(0.1);
	borderColor = "purple";
	gcdbarColor = "violet";
	barTexture = "Interface\\Buttons\\WHITE8X8"
	--------------------------------------------------------------------
	--------------------------------------------------------------------
	-- not settings
	local grid = {}
	local spells
	--------------------------------------------------------------------
	--------------------------------------------------------------------
		-- spells

	if UnitName("player") == "Khthon" then

		spells = {
		{"Cone of Cold",{0,0,1,1} },
		{"Frost Nova", {0,0,1,1}  },
		{"Dragon's Breath", {1,0,0,1}  },
		{"Blast Wave", {1,0,0,1}  },
		{"Blink", {1,0,1,1}  },
		{"Counterspell", {1,0,1,1}  }
		}

		grid = {
			{ 1, 2 },
			{ 3, 4 },
			{ 5, 6 }
		}
	elseif UnitName("player") == "Dafrito" then
		WorldFrame:Hide()
	end
	--------------------------------------------------------------------
	--------------------------------------------------------------------


	math.round = function(num,idp)
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
	local gcd = 61304
	local caid = CreateFrame("Frame",nil,UIParent)
	caid:SetFrameStrata("LOW")
	Anchors.Center(caid, 0, -100);
	Frames.Size(caid,width, height)

	Frames.Backdrop(caid, 2);
	Frames.Color(caid, bgColor);
	Frames.BorderColor(caid, borderColor);

	if enableGCD then
		caid.gcdbar = CreateFrame("Frame",nil,caid)
		Anchors.ShareHorizontals(caid.gcdbar);
		caid.gcdbar:SetFrameLevel(caid:GetFrameLevel()+5)
		caid.gcdbar:SetHeight(2);
		caid.gcdbar.texture = caid.gcdbar:CreateTexture(nil,"background")
		caid.gcdbar.texture:SetAllPoints(caid.gcdbar)
		Frames.Color(caid.gcdbar.texture, borderColor);


	   local start, dur, perc
	   Timing.Every(0.01, function()
		 local height = Frames.Height(caid);
		 start,dur = GetSpellCooldown(gcd)
		 caid.gcdbar:Hide()
		 if start ~= 0 then
		    perc = (GetTime() - start) / dur
		    if perc < 1 then
		       caid.gcdbar:Show()
			   Anchors.Share(caid.gcdbar, "bottom", 0, (height-caid.gcdbar:GetHeight())*perc);
		    end
		 end

	   end)
	end

	local ss = function (frame, current, max)
		local perc = current/max
		if not frame.bar then
			frame.bar = frame:CreateTexture(nil, "background")
			frame.bar:SetTexture(barTexture)
			frame.bar:SetBlendMode(blendType)
			frame.bar:SetPoint("Left")
		end
		frame.bar:SetWidth(frame:GetWidth()*perc)
	end

	if enablePowerBar then
		local colors = { -- all colors just approximate
		[0] = "blue", --mana
		[1] = "red", -- rage
		[2] = "orange", -- focus
		[3] ="yellow", -- energy
		[4] = "gray", -- nothing
		[5] = "gray", -- nothing
		[6] = "cyan" -- runic power
		}
		local power = UnitPowerType("player")
		caid.powerbar = CreateFrame("Frame",nil, caid)
		caid.powerbar:SetHeight(8)
		caid.powerbar:SetWidth(caid:GetWidth()-gridGapH*2)
		caid.powerbar:SetPoint("Top", caid, "Bottom",0,-5)
		caid.powerbar:SetFrameLevel(caid:GetFrameLevel()+4)
		caid.powerbar.SetStatus = ss
		caid.powerbar.text = caid.powerbar:CreateFontString(nil, 'OVERLAY')
		caid.powerbar.text:SetAllPoints(caid.powerbar)
		caid.powerbar.text:SetFont(STANDARD_TEXT_FONT, 7, 'OUTLINE')
		caid.powerbar.text:SetText("")
		Timing.Every(0.01, function()
			caid.powerbar:SetStatus(UnitPower("player"),UnitPowerMax("player") )
			Frames.Color(caid.powerbar.bar,colors[power])
			if power == 0 then
				caid.powerbar.text:SetText(math.round(  (UnitPower("player")/UnitPowerMax("player"))*100 ) )
			else
				caid.powerbar.text:SetText(UnitPower("player"))
			end
		end)
	end
	local scd = function(frame,start,duration)
	   if start == 0 then
	      frame.onTrueCooldown = false
	   elseif start ~= GetSpellCooldown(gcd) then
	      frame.onTrueCooldown = true
	   end
	   if frame.onTrueCooldown then
	      local perc = (GetTime() - start) / duration
	      frame.bar:SetWidth(frame:GetWidth()*perc)
	   end
	end

	local CreateCooldownBar = function(spell)
	   local cd = CreateFrame("Frame", nil, caid)
	   cd:SetFrameLevel(caid:GetFrameLevel()+4)
	   cd.spell = spell
	   cd.bar = cd:CreateTexture(nil,"artwork")
	   cd.bar:SetTexture(barTexture)
	   cd.bar:SetBlendMode(blendType)
	   cd.bar:SetPoint("Left")
	   cd.onTrueCooldown = false
	   cd.SetCooldown = scd
	   return cd
	end


	for k,v in ipairs(spells) do
		spells[k] = CreateCooldownBar(v[1])
		spells[k].bar:SetVertexColor( unpack(v[2]) )
		for l, u in ipairs(grid) do
			for m,w in ipairs(u) do
				if w == k then
					grid[l][m] = spells[k]
				end
			end
		end
	end
	-- autoadjust the bars inside the main frame
	-- put false if you want a nonexistent bar
	-- otherwise the other bar will expand into that space


	local insets = Frames.Insets(caid)
	local insetsH = insets.left + insets.right
	local insetsV = insets.top + insets.bottom
	local h = (caid:GetHeight()-insetsV) - (gridGapV*(#grid+1))
	h = h/#grid
	local w

	for k,v in ipairs(grid) do
		w = (caid:GetWidth()-insetsH) - (gridGapH*(#v+1))
		w = w/#v
		for l,u in ipairs(v) do
			if u then
				u:SetSize(w,h)
				u:SetPoint(
				"TopLeft",caid,"TopLeft",
				gridGapH*l+w*(l-1)+insets.left, -(gridGapV*k+h*(k-1)+insets.top)
				)
				u.bar:SetSize(w,h)
			end
		end
	end

	Timing.Every(0.05, function()
	      for k,v in ipairs(grid) do
		 for l,u in ipairs(v) do
		    cd = 0
		    if u then

		       u:SetCooldown(GetSpellCooldown(u.spell))
		       if u.onTrueCooldown then
		          u.bar:SetAlpha(0.5)
		       else
		          u.bar:SetAlpha(1)
		       end
		    end
		 end
	      end
	end)
	if enableMageArmorBorder then
		local color
		Timing.Every(0.1, function()
			if UnitBuff("player", "Mage Armor") then
				color = "purple"
			elseif UnitBuff("player", "Molten Armor") then
				color = "red"
			elseif UnitBuff("player", "Frost Armor") then
				color = "cyan"
			else
				color = "black"
			end
			if enableGCD then
				Frames.Color(caid.gcdbar.texture, color)
			end
			Frames.BorderColor(caid, color)

		end)
	end

end;

