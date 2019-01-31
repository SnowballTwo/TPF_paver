local tu = require "texutil"

function data()
return {
	detailTex = tu.makeTextureMipmapRepeat("ground_texture/industry_gravel_small_01_albedo.dds", true, true),
	detailNrmlTex = tu.makeTextureMipmapRepeat("ground_texture/industry_gravel_small_01_normal.dds", true, true, true),
	detailSize = { 16.0,16.0 },
	colorTex = tu.makeTextureMipmapRepeat("models/industry/overlay_textures/small_02.tga", false),
	colorSize = 256.0
}
end
