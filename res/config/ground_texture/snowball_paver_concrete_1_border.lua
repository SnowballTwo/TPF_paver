local tu = require "texutil"

function data()
return {
	detailTex = tu.makeTextureMipmapRepeat("ground_texture/industry_concrete_01_albedo.dds", true, true),
	detailNrmlTex = tu.makeTextureMipmapRepeat("ground_texture/industry_concrete_01_normal.dds", true, true, true),
	--detailSize = { 16.0, 16.0 }
	detailSize = { 32.0, 32.0 },
	colorTex = tu.makeTextureMipmapRepeat("models/industry/overlay_textures/small_02.tga", false),
	colorSize = 256.0,
	alphaTex = tu.makeTextureMipmapClampVertical("ground_texture/snowball_paver_border_alpha.tga", false),
	alphaSize = { 32.0, 4.0 },
}
end
