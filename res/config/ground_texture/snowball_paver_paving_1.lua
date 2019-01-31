local tu = require "texutil"

function data()
return {
	detailTex = tu.makeTextureMipmapRepeat("streets/old_medium_paving.tga", false),
	detailNrmlTex = tu.makeTextureMipmapRepeat("streets/old_medium_paving_nrml.tga", false),
	detailSize = { 16.0,16.0 },
	colorTex = tu.makeTextureMipmapRepeat("ground_texture/snowball_paver_overlay.tga", false),
	colorSize = 256.0
	
}
end
