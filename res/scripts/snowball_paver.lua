local transf = require "transf"
local vec4 = require "vec4"

local vec3 = require "snowball_paver_vec3"
local mat3 = require "snowball_paver_mat3"
local poly = require "snowball_paver_polygon"
local plan = require "snowball_paver_planner"
local paver = {}

paver.markerStore = nil
paver.finisherStore = nil
paver.lastMarker = nil
paver.markerId = "asset/snowball_paver_marker.mdl"
paver.finisherId = "asset/snowball_paver_finisher.mdl"

paver.grounds = {
    {
        name = _("snowball_paver_concrete_1"),
        fill = "snowball_paver_concrete_1",
        stroke_outer = "snowball_paver_concrete_1_border"
    },
    {name = _("snowball_paver_concrete_2"), fill = "town_concrete", stroke_outer = "town_concrete_border"},
    {
        name = _("snowball_paver_paving_1"),
        fill = "snowball_paver_paving_1",
        stroke_outer = "snowball_paver_paving_1_border"
    },
    {
        name = _("snowball_paver_paving_2"),
        fill = "snowball_paver_paving_2",
        stroke_outer = "snowball_paver_paving_2_border"
    },
    {
        name = _("snowball_paver_gravel_1"),
        fill = "snowball_paver_gravel_1",
        stroke_outer = "snowball_paver_gravel_1_border"
    },
    {
        name = _("snowball_paver_gravel_2"),
        fill = "snowball_paver_gravel_2",
        stroke_outer = "snowball_paver_gravel_2_border"
    },
    {name = _("snowball_paver_soil_1"), fill = "snowball_paver_soil_1", stroke_outer = "snowball_paver_soil_1_border"}
}

paver.fences = {
    {
        name = "snowball_paver_fence_stockade",
        post = nil,
        middle = "asset/snowball_paver_fences/stockade_middle.mdl",
        length = 3.3734
    },
    {
        name = "snowball_paver_fence_rods",
        post = nil,
        middle = "asset/snowball_paver_fences/rods_middle.mdl",
        length = 2.5
    },
    {
        name = "snowball_paver_fence_mesh",
        post = nil,
        middle = "asset/snowball_paver_fences/mesh_middle.mdl",
        length = 3.05
    }
}

function paver.getGroundNames()
    local result = {}
    for i = 1, #paver.grounds do
        result[#result + 1] = paver.grounds[i].name
    end
    return result
end

function paver.updateMarkers()
    if not paver.markerStore then
        paver.markerStore = {}
    end
    if not paver.finisherStore then
        paver.finisherStore = {}
    end

    return plan.updateEntityLists(paver.markerId, paver.markerStore, paver.finisherId, paver.finisherStore)
end

function paver.getPolygon(markers)
    local polygon = {}

    for i = 1, #markers do
        local marker = markers[i]
        polygon[#polygon + 1] = {marker.position[1], marker.position[2], marker.position[3]}
    end

    if #polygon == 0 then
        return nil
    end

    return polygon
end

function paver.fenceSegment(a, b, center, fence, rotation, result)
    local length = fence.length

    a[3] = game.interface.getHeight({a[1] + center[1], a[2] + center[2]}) - center[3]
    b[3] = game.interface.getHeight({b[1] + center[1], b[2] + center[2]}) - center[3]

    local v = vec3.sub(b, a)
    local vn = vec3.mul(vec3.length(v) / length, vec3.normalize(v))
    local o = vec3.normalize({v[2], -v[1], 0.0})

    local affine = mat3.affine(vn, o)

    local transform =
        transf.new(
        vec4.new(affine[1][1], affine[2][1], affine[3][1], .0),
        vec4.new(affine[1][2], affine[2][2], affine[3][2], .0),
        vec4.new(affine[1][3], affine[2][3], affine[3][3], .0),
        vec4.new(a[1], a[2], a[3], 1.0)
    )

    if fence.middle then
        result.models[#result.models + 1] = {
            id = fence.middle,
            transf = transform
        }
    end
    if fence.post then
        result.models[#result.models + 1] = {
            id = fence.post,
            transf = transf.rotZTransl(rotation, {x = b[1], y = b[2], z = b[3]})
        }
    end
end

function paver.fence(pavepoly, center, fence, result)
    local length = fence.length

    --Calculate the correct rotation of fence posts for every segment, no matter the orientation of the polygon
    local rf = 1
    if poly.isClockwise(pavepoly) then
        rf = -1
    end
    h = game.interface.getHeight({pavepoly[1][1] + center[1], pavepoly[1][2] + center[2]}) - center[3]

    if fence.post then
        result.models[#result.models + 1] = {
            id = fence.post,
            transf = transf.rotZTransl(
                math.atan2(rf * (pavepoly[2][2] - pavepoly[1][2]), rf * (pavepoly[2][1] - pavepoly[1][1])),
                {x = pavepoly[1][1], y = pavepoly[1][2], z = h}
            )
        }
    end
    for i = 1, #pavepoly - 1 do
        local a = pavepoly[i]
        local b = pavepoly[i + 1]
        local r = math.atan2(rf * (b[2] - a[2]), rf * (b[1] - a[1]))
        local v = vec3.sub(b, a)
        local vn = vec3.normalize(v)

        local segmentLength = vec3.length(v)
        local segmentCount = math.floor(segmentLength / length + 0.5)
        if segmentCount == 0 then
            segmentCount = 1
        end

        local vs = vec3.mul(1 / segmentCount, v)

        for j = 1, segmentCount do
            local sa = vec3.add(a, vec3.mul(j - 1, vs))
            local sb = vec3.add(sa, vs)

            paver.fenceSegment(sa, sb, center, fence, r, result)
        end
    end
end

function paver.plan(result, type)
    if (paver.finisherStore) then
        for i = 1, #paver.finisherStore do
            local finisher = paver.finisherStore[i]
            game.interface.bulldoze(finisher.id)
        end
    end

    paver.finisherStore = {}

    for i = 1, #paver.markerStore + 1 do
        result.models[#result.models + 1] = {
            id = "asset/snowball_paver_marker.mdl",
            transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
        }
    end

    local poly = paver.getPolygon(paver.markerStore)
    local color = {0.9, 0.85, 0.8, 1}

    if poly then
        if #poly == 1 then
            local pavezone = {
                polygon = {{poly[1][1] - 5, poly[1][2], poly[1][3]}, {poly[1][1] + 5, poly[1][2], poly[1][3]}},
                draw = true,
                drawColor = color
            }
            game.interface.setZone("pavezone", pavezone)
        else
            local pavezone = {polygon = poly, draw = true, drawColor = color}
            game.interface.setZone("pavezone", pavezone)
        end
    end
end

function paver.reset(result)
    result.models[#result.models + 1] = {
        id = "asset/snowball_paver_finisher.mdl",
        transf = {0.01, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 1}
    }

    game.interface.setZone("pavezone", nil)

    if not paver.markerStore then
        return
    end

    for i = 1, #paver.markerStore do
        local marker = paver.markerStore[i]
        game.interface.bulldoze(marker.id)
    end

    paver.markerStore = {}
end

function paver.pave(result, ground, stroke, fence, interactive)
    result.models[#result.models + 1] = {
        id = "asset/snowball_paver_finisher.mdl",
        transf = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
    }

    if not paver.markerStore then
        return
    end

    game.interface.setZone("pavezone", nil)
    local pavepoly = paver.getPolygon(paver.markerStore)

    for i = 1, #paver.markerStore do
        local marker = paver.markerStore[i]
        game.interface.bulldoze(marker.id)
    end

    paver.markerStore = {}

    if (not pavepoly) or (#pavepoly < 3) then
        return result
    end

    if poly.isSelfIntersecting(pavepoly) then
        return result
    end

    if poly.isClockwise(pavepoly) then
        pavepoly = poly.reverse(pavepoly)
    end

    local center = poly.makeCentered(pavepoly)

    if fence then
        game.interface.buildConstruction(
            "asset/snowball_paver_fence.con",
            {
                outline = pavepoly,
                fence = fence,
                center = {center[1], center[2], center[3]}
            },
            {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, center[1], center[2], center[3], 1}
        )
    end

    local entity =
        game.interface.buildConstruction(
        "asset/snowball_paver_field.con",
        {
            outline = pavepoly,
            ground = ground,
            stroke = stroke,
            center = {center[1], center[2], center[3]}
        },
        {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, center[1], center[2], center[3], 1}
    )
    if interactive then
        local player = game.interface.getPlayer()
        game.interface.setPlayer(entity, player)
    end
end

function paver.lock(interactive)
    local player = nil
    if interactive then
        player = game.interface.getPlayer()
    end

    local fields =
        game.interface.getEntities(
        {pos = {0, 0}, radius = 100000},
        {type = "CONSTRUCTION", fileName = "asset/snowball_paver_field.con"}
    )
    for i = 1, #fields do
        game.interface.setPlayer(fields[i], player)
    end
end

return paver
