BLENDOPERATION_ADD              = 0x1
BLENDOPERATION_SUBTRACT         = 0x2
BLENDOPERATION_REV_SUBTRACT     = 0x3
BLENDOPERATION_MINIMUM          = 0x4
BLENDOPERATION_MAXIMUM          = 0x5
BLENDFACTOR_ZERO                = 0x1
BLENDFACTOR_ONE                 = 0x2
BLENDFACTOR_SRC_COLOR           = 0x3
BLENDFACTOR_ONE_MINUS_SRC_COLOR = 0x4
BLENDFACTOR_SRC_ALPHA           = 0x5
BLENDFACTOR_ONE_MINUS_SRC_ALPHA = 0x6
BLENDFACTOR_DST_COLOR           = 0x7
BLENDFACTOR_ONE_MINUS_DST_COLOR = 0x8
BLENDFACTOR_DST_ALPHA           = 0x9
BLENDFACTOR_ONE_MINUS_DST_ALPHA = 0xA

def compose_blendmode(src_color_factor, dst_color_factor, color_operation, src_alpha_factor, dst_alpha_factor, alpha_operation)
  (color_operation  << 0)  |
  (src_color_factor << 4)  |
  (dst_color_factor << 8)  |
  (alpha_operation  << 16) |
  (src_alpha_factor << 20) |
  (dst_alpha_factor << 24)
end

HOLE_PUNCH_BLENDMODE = compose_blendmode(BLENDFACTOR_ZERO,
                                         BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                         BLENDOPERATION_ADD,
                                         BLENDFACTOR_ZERO,
                                         BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                         BLENDOPERATION_ADD)
def tick args
  args.outputs.background_color = [30, 30, 30]
  args.outputs[:ring].set w: 512, h: 512, background_color: [0, 0, 0, 0]
  args.outputs[:ring].primitives << { x: 256, y: 256, w: 512, h: 512, path: "sprites/solid-circle.png", anchor_x: 0.5, anchor_y: 0.5, r: 0, g: 128, b: 128 }
  args.outputs[:ring].primitives << { x: 256,
                                      y: 256,
                                      w: 511 * Math.sin((Kernel.tick_count % 360).to_radians).abs,
                                      h: 511 * Math.sin((Kernel.tick_count % 360).to_radians).abs,
                                      path: "sprites/solid-circle.png",
                                      anchor_x: 0.5,
                                      anchor_y: 0.5,
                                      blendmode: HOLE_PUNCH_BLENDMODE }
  args.outputs<< { x: 640, y: 360, w: 512, h: 512, path: :ring, anchor_x: 0.5, anchor_y: 0.5 }
end
