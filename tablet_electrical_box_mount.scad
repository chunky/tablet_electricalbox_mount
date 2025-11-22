// Tablet Kiosk Wall Mount for Single-Gang Electrical Box

// Designed to mount to standard single-gang box screws
// Open top for sliding tablet in, cable management at bottom

// Clearance to add to tablet dimensions
tablet_clearance = 1.0;
// iPad dimensions (iPad 8th Gen model A2270 - 10.2 inch)
tablet_width = 174.1 + tablet_clearance;  // 6.8 inches
tablet_height = 250.6 + tablet_clearance; // 9.8 inches
tablet_depth = 7.5 + tablet_clearance;    // 0.29 inches

// Frame parameters
frame_width = 2;  // Width of frame border
frame_depth = 11.5; // How deep the frame pocket is
wall_plate_thickness = 4; // Back plate against wall
lip_height = 4;   // Small lip to hold iPad sides and bottom
bottom_frame_height = 35;  // Taller bottom frame to cover USB plug
cable_channel_width = 15;  // Narrow channel at front for cable only
cable_clearance_back = 60;  // Wide clearance in back for connector

// Single-gang box parameters
gang_box_screw_spacing = 83.3;  // Standard vertical spacing
gang_box_width = 70;

// Cable clearance hole in back plate - positioned between the screw holes but offset to the side
// This is where cable exits from center of electrical box
cable_offset = 20;  // Offset to side of screws
cable_clearance_width = 30; // Width of slot cable goes through
cable_clearance_height = 50; // Cabling gap

// Skeletonize back plate. Simplify, then add lightness
hole_spacing = 15;
hole_dia = 13;

// Bevel parameters
bevel_size = 2;  // Size of front edge bevels

// Testing option - set to true to print only bottom half for test fitting
test_bottom_only = false;  // Change to true for test print

// Bambu A1 printer constraint - max Y build dimension is 256mm
max_build_y = 195;
// Calculate the actual frame height to use (limited by printer)
frame_y_height = min(tablet_height + bottom_frame_height, max_build_y - 2*frame_width);

// Module to create a 45-degree chamfer cut
module bevel(length, size=bevel_size) {
    rotate([0, 90, 0])
    linear_extrude(length)
        polygon([[0, 0], [size, 0], [0, size]]);
}

module main_body() {
    difference() {
        union() {
            // Main back plate with reinforcement ribs
            cube([tablet_width + 2*frame_width,
                  frame_y_height,  // Limited by printer build volume
                  wall_plate_thickness]);
            
            // Side frames (left and right)
            cube([frame_width, frame_y_height,
                  wall_plate_thickness + frame_depth]);

            translate([tablet_width + frame_width, 0, 0])
                cube([frame_width, frame_y_height,
                      wall_plate_thickness + frame_depth]);
            
            // Bottom frame with cable channel - taller to cover USB plug
            difference() {
                cube([tablet_width + 2*frame_width, bottom_frame_height,
                      wall_plate_thickness + frame_depth]);

                // Wide cable clearance in back for connector - does NOT go through to front
                translate([frame_width + tablet_width/2 - cable_clearance_back/2,
                           -1,
                           wall_plate_thickness])
                cube([cable_clearance_back,
                          3*bottom_frame_height + 2,
                          frame_depth - 2]);  // Stops before reaching front face

                // Opening at very bottom for USB cable to plug into iPad from below
                translate([frame_width + tablet_width/2 - cable_channel_width/2,
                           -1,
                           -1])
                    cube([cable_channel_width,
                          10*frame_width + 2,  // Just through the bottom edge
                          wall_plate_thickness + 2]);
            }
            
            // Small lips on sides to hold iPad
            translate([frame_width, frame_width, wall_plate_thickness + tablet_depth])
                cube([lip_height, frame_y_height - frame_width, frame_depth - tablet_depth]);

            translate([frame_width + tablet_width - lip_height, frame_width, wall_plate_thickness + tablet_depth])
                cube([lip_height, frame_y_height - frame_width, frame_depth - tablet_depth]);

            // Bottom lip extends fully across - NO gap at front
            translate([frame_width, frame_width, wall_plate_thickness + tablet_depth])
                cube([tablet_width, bottom_frame_height, frame_depth - tablet_depth]);
        }
        
        // Mounting screw holes (standard single-gang spacing)
        screw_hole_dia = 4;
        screw_from_bottom = frame_width + tablet_height/3 - gang_box_screw_spacing/2;  // Screws center 1/3 up tablet

        // Vertical cable channel from electrical box (between screws) down to iPad charging port
        translate([frame_width + tablet_width/2 + cable_offset - cable_channel_width/2,
                   -1,
                   -1])
            cube([cable_channel_width,
                  screw_from_bottom + cable_clearance_height/2 + 1,
                  wall_plate_thickness + tablet_depth - 1]);

        translate([frame_width + tablet_width/2, screw_from_bottom, -1])
            cylinder(h=wall_plate_thickness + 2, d=screw_hole_dia, $fn=30);

        translate([frame_width + tablet_width/2, screw_from_bottom + gang_box_screw_spacing, -1])
            cylinder(h=wall_plate_thickness + 2, d=screw_hole_dia, $fn=30);

        // Countersink for screw heads
        translate([frame_width + tablet_width/2, screw_from_bottom, wall_plate_thickness/2])
            cylinder(h=wall_plate_thickness, d=8, $fn=30);

        translate([frame_width + tablet_width/2, screw_from_bottom + gang_box_screw_spacing, wall_plate_thickness/2])
            cylinder(h=wall_plate_thickness, d=8, $fn=30);
        
        // Brick-pattern offset holes for better strength and material savings
        // Move circles closer in Y-direction to account for offsets
        y_adjustment = 1.2;
        for(y_index = [3 : floor(y_adjustment * (frame_y_height - hole_dia) / hole_spacing) - 1]) {
            y = hole_spacing + y_index * hole_spacing / y_adjustment;
            // Offset every other row by half spacing for brick pattern
            x_offset = (y_index % 2) * hole_spacing / 2;

            for(x = [-tablet_width/2 + hole_spacing : hole_spacing : tablet_width/2 - hole_spacing]) {
                // Skip holes near mounting screws
                if (abs((tablet_width/2 + x + x_offset) - tablet_width/2) > 15 ||
                    (abs(y - screw_from_bottom) > 15 &&
                     abs(y - (screw_from_bottom + gang_box_screw_spacing)) > 15)) {
                    translate([frame_width + tablet_width/2 + x + x_offset, y, -1])
                        cylinder(h=wall_plate_thickness + 2, d=hole_dia, $fn=30);
                }
            }
        }
    }
}

// Module to apply bevels to all front edges
module beveled_body() {
    front_z = wall_plate_thickness + frame_depth;
    total_width = tablet_width + 2*frame_width;

    difference() {
        
        main_body();

        // Left side frame - outer front edge (vertical along Y)
        translate([0, 0, front_z])
            rotate([270, 0, 90])
            bevel(frame_y_height);

        // Right side frame - outer front edge (vertical along Y)
        translate([total_width, 0, front_z])
            rotate([0, 0, 90])
            bevel(frame_y_height);

        // Bottom frame - outer front edge (horizontal along X)
        translate([0, 0, front_z])
            bevel(total_width);

        // Top frame - outer front edge (horizontal along X)
        translate([0, frame_y_height, front_z])
            rotate([270, 0, 0])
            bevel(total_width);
            
        // Bottom left frame corner
        rotate([180, 270, 180])
            bevel(frame_depth+wall_plate_thickness);
        
        // Bottom right frame corner
        translate([total_width, 0, 0])
        rotate([180, 270, 270])
            bevel(frame_depth+wall_plate_thickness);
            
        // Top left frame corner
        translate([0, frame_y_height, 0])
        rotate([180, 270, 90])
            bevel(frame_depth+wall_plate_thickness);

        // Top right frame corner
        translate([total_width, frame_y_height, 0])
        rotate([180, 270, 0])
            bevel(frame_depth+wall_plate_thickness);
    }
}

// Render the mount
if (test_bottom_only) {
    // Only render bottom half for testing - includes screws and cable management
    intersection() {
        beveled_body();
        translate([-10, -10, -1])
            cube([tablet_width + 2*frame_width + 20,
                  tablet_height/3,  // Half height plus extra for cable area
                  wall_plate_thickness + frame_depth + 2]);
    }
} else {
    // Render full mount
    beveled_body();
}

// Visual reference (comment out for printing)
%translate([frame_width, frame_width, wall_plate_thickness])
    cube([tablet_width, tablet_height, tablet_depth]);

