

----
woody = woody or {}
local woody = woody

woody.maxHealth = 50000
woody.minHealth = 0


----
function woody.applyDamage( ent, filter )
    local health = ent:Health() - filter:GetDamage()

    if health <= 0 then
        ent:Remove()
    else
        ent:SetHealth( health )
    end
end

hook.Add( "EntityTakeDamage", "Woody_Breakable", function( ent, filter )
    if not IsValid( ent ) or not filter then return end
    if not ent.OnDieFunctions or not ent.OnDieFunctions.Woody_CreateGibs then return end

    woody.applyDamage( ent, filter )
end )


----
local zero = Vector()

local function createGibber()
    if IsValid( woody.gibber ) then
        return woody.gibber
    end

    woody.gibber = ents.Create( "base_anim" )
    woody.gibber:SetModel( "models/props_phx/construct/wood/wood_panel1x1.mdl" )
    woody.gibber:Spawn()
    woody.gibber:Activate()
    woody.gibber:PrecacheGibs()

    return woody.gibber
end

local function breakAt( gibber, pos, force )
    gibber:SetPos( pos )
    gibber:GibBreakClient( force )
end

local function createGibs( ent )
    if not IsValid( ent ) then return end

    local gibber = createGibber()

    if IsValid( gibber ) then
        local vel = ent:GetVelocity()

        breakAt( gibber, ent:LocalToWorld( ent:OBBCenter() ), vel )
        --breakAt( gibber, ent:LocalToWorld( ent:OBBMins() ), vel )
        --breakAt( gibber, ent:LocalToWorld( ent:OBBMaxs() ), vel )

        gibber:SetPos( zero )
    end
end


----
woody.applyModifier = function( ply, ent, data )
    ent:CallOnRemove( "Woody_CreateGibs", createGibs )

    if tonumber( data.health ) then
        data.health = math.Clamp( tonumber( data.health ), woody.minHealth, woody.maxHealth )
        ent:SetHealth( data.health )
        ent:SetMaxHealth( data.health )
    end

    if data.dupe then
        duplicator.StoreEntityModifier( ent, "Woody_Dupe", { type = data.type, health = data.health } )
    end

    ent:SetNW2Bool( "IsWoody", true )
end

duplicator.RegisterEntityModifier( "Woody_Dupe", function( ply, ent, data )
    woody.applyModifier( ply, ent, data )
end )
