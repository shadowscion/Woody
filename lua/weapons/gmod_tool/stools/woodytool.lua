
include( "woody/woodylib.lua" )

TOOL.Category = "Render"
TOOL.Name     = "#tool.woodytool.name"
TOOL.Command  = nil

if CLIENT then

    TOOL.ClientConVar = {
        health = 100,
    }

    TOOL.Information = {
        { name = "left", stage = 0 },
        { name = "right", stage = 0 },
        { name = "reload", stage = 0 },
    }

    language.Add( "tool.woodytool.name", "Woody" )
    language.Add( "tool.woodytool.desc", "Turn props into... wood!" )
    language.Add( "tool.woodytool.left", "Apply to selection" )
    language.Add( "tool.woodytool.right", "Select an entity, hold [SHIFT] to select all entities within a radius" )
    language.Add( "tool.woodytool.reload", "Deselect an entity, hold [SHIFT] to deselect all entities" )

    function TOOL:RightClick( tr )
        return true
    end


    function TOOL:LeftClick( tr )
        return true
    end


    function TOOL:Reload( tr )
        return true
    end


    function TOOL.BuildCPanel( self )
        local slider = self:NumSlider( "Prop Health", "woodytool_health", 0, 50000, 0 )
    end


    function TOOL:DrawHUD()
        local tr = LocalPlayer():GetEyeTrace()

        if not tr.Hit or not tr.Entity or not tr.Entity:GetNW2Bool( "IsWoody" ) then return end

        local pos  = tr.Entity:GetPos():ToScreen()

        surface.SetTextPos( pos.x, pos.y )
        surface.SetTextColor( 255, 255, 255 )
        surface.DrawText( string.format( "%d/%d", tr.Entity:Health(), tr.Entity:GetMaxHealth() ) )
    end

else

    TOOL.selection = {}
    TOOL.selectColor = Color( 125, 255, 125, 125 )

    local select_class, select_baseclass = {}, {}
    select_class.prop_physics = true


    function TOOL:Select( ent )
        if not self.selection then
            self.selection = {}
        end

        if self.selection[ent] or not ent or not IsValid( ent ) then return end

        local class, selector = ent:GetClass()

        selector = select_class[class]
        if not selector then
            selector = select_baseclass[baseclass.Get( class ).Base]
            if not selector then return end
        end

        local color = ent:GetColor()
        if color.a == 0 then return end

        self.selection[ent] = { color = color, mode = ent:GetRenderMode(), selector = selector }

        ent:SetColor( self.selectColor )
        ent:SetRenderMode( RENDERMODE_TRANSALPHA )
        ent:CallOnRemove( "Woody_ToolSelected", function( e ) if self then self.selection[e] = nil end end )
    end


    function TOOL:Deselect( ent )
        if not self.selection then
            self.selection = {}
        end

        if not self.selection[ent] then return end

        if IsValid( ent ) then
            ent:SetColor( self.selection[ent].color )
            ent:SetRenderMode( self.selection[ent].mode )
            ent:RemoveCallOnRemove( "Woody_ToolSelected" )
        end

        self.selection[ent] = nil
    end


    function TOOL:Reload( tr )
        if not tr.Hit then return false end

        if self:GetOwner():KeyDown( IN_SPEED ) then
            for ent in pairs( self.selection ) do
                self:Deselect( ent )
            end
        else
            if not IsValid( tr.Entity ) then return false end
            self:Deselect( tr.Entity )
        end

        return true
    end


    function TOOL:RightClick( tr )
        if not tr.Hit then return false end

        if self:GetOwner():KeyDown( IN_SPEED ) then
            for _, ent in pairs( ents.FindInSphere( tr.HitPos, 1000 ) ) do
                self:Select( ent )
            end
        else
            if not IsValid( tr.Entity ) then return false end
            self:Select( tr.Entity )
        end

        return true
    end


    function TOOL:LeftClick( tr )
        if not tr.Hit or not self.selection or next( self.selection ) == nil then return false end

        for ent in pairs( self.selection ) do
            woody.applyModifier( self:GetOwner(), ent, { dupe = true, health = self:GetClientNumber( "health" ) } )
            self:Deselect( ent )
        end

        return true
    end

end
