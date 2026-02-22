// ================================================================
// Nestout 15000mAh — Waterproof Cable Passthrough Cap
// For McMaster-Carr 5302N121 Wraparound Cord Grip (M25)
// ================================================================
//
// REQUIRES: BOSL2 library for thread generation
//   Install: https://github.com/BelfrySCAD/BOSL2
//   Or in OpenSCAD: File → Library Manager → Install BOSL2
//
// ASSEMBLY (bottom to top):
//   1. Gland shaft threads into M25 hole from above
//   2. Gland hex body/flange sits on cap top surface
//   3. (Optional) outer locknut above gland hex for extra hold
//   4. Cap threads onto Nestout battery (~2 turns)
//   5. Split rubber bung wraps around cable
//   6. Gland compression cap tightens to seal cable
//
// PRINT SETTINGS:
//   Material: PETG or ASA (NO PLA — too brittle for threads)
//   Layer height: 0.12–0.15mm
//   Infill: 100% (small part, just do it)
//   Orientation: Open/threaded end DOWN on build plate
//   Supports: None needed
//   Walls/perimeters: 4+ for thread strength
//
// ================================================================

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// ========================
// MEASURED VALUES — Nestout 15000mAh battery body
// ========================

// Nestout battery thread (male threads on battery body)
nestout_thread_id  = 25.5;   // Male thread major diameter (crest to crest)
nestout_pitch      = 2.2;    // Thread pitch (trapezoidal)
nestout_engagement = 10.0;   // Total depth cap screws onto battery
nestout_thread_zone = 5.0;   // Upper 5mm of engagement has threads
nestout_smooth_zone = 5.0;   // Lower 5mm is smooth (O-ring contact)

// ========================
// McMASTER GLAND (5302N121) — from drawing
// ========================

m25_pitch          = 1.5;    // Standard M25 fine pitch
gland_shaft_length = 13.2;   // 0.52" total shaft length

// ========================
// DESIGN PARAMETERS — tune these for fit
// ========================

// Thread tolerances (per side)
nestout_slop   = 0.20;       // Clearance on Nestout threads
m25_slop       = 0.15;       // Clearance on M25 threads

// Overall geometry
cap_od           = 40.0;     // Outer diameter (clears 33mm gland hex body)
top_plate_height = 8.0;      // M25 thread depth
transition_height = 2.0;     // Taper from Nestout bore to shaft clearance bore

// Shaft clearance — the gland shaft protrudes below the M25 threads.
// Cable routes straight from shaft exit to the USB port below.
shaft_clearance  = 1.0;      // Gap below shaft tip (mm)
cavity_height    = gland_shaft_length - top_plate_height + shaft_clearance;
                              // ≈6.2mm — just clears the unengaged shaft
cavity_id        = 26.0;     // Interior bore — must clear M25 shaft OD (~25mm)

// Exterior grip profile
groove_count     = 6;        // Finger grooves around circumference
groove_depth     = 1.5;      // How deep grooves cut into surface (mm)
groove_cutter_r  = 4.0;      // Cross-section radius of each groove
top_fillet       = 1.0;      // Exterior top edge rounding
bottom_fillet    = 1.5;      // Exterior bottom edge rounding

bottom_chamfer   = 1.5;      // Bore chamfer on bottom (thread lead-in)
top_chamfer      = 1.0;      // Bore chamfer on top (gland thread lead-in)
thread_angle     = 29;       // Thread flank angle for Nestout threads

// ========================
// DERIVED DIMENSIONS
// ========================

smooth_bore_id = nestout_thread_id + nestout_slop * 2;
m25_bore_id    = 25.0;  // Nominal M25
total_height   = nestout_engagement + transition_height + cavity_height + top_plate_height;

// Sanity checks
echo(str("── Cap Dimensions ──"));
echo(str("  Total height: ", total_height, "mm"));
echo(str("  Outer diameter: ", cap_od, "mm"));
echo(str("  Smooth bore ID: ", smooth_bore_id, "mm"));
echo(str("  Cavity height: ", cavity_height, "mm"));
echo(str("  Shaft protrusion into cavity: ",
    gland_shaft_length - top_plate_height, "mm"));
echo(str("  Clearance below shaft: ", shaft_clearance, "mm"));
echo(str("  Nestout thread zone: ", nestout_thread_zone, "mm @ ", nestout_pitch, "mm pitch"));
echo(str("  M25 thread depth: ", top_plate_height, "mm @ ", m25_pitch, "mm pitch"));
echo(str("  Nestout thread turns: ", nestout_thread_zone / nestout_pitch));
echo(str("  M25 thread turns: ", top_plate_height / m25_pitch));

// ========================
// MODULES
// ========================

$fn = 72;  // Circle resolution — increase to 120 for final export

// --- Round exterior with finger-retention grooves ---
module cap_exterior(height) {
    // Grooves span the full exterior, inset from the fillet radii
    groove_bottom = bottom_fillet + 1;
    groove_top    = height - top_fillet - 1;

    difference() {
        // Round body with filleted top and bottom edges
        cyl(d = cap_od, h = height,
            rounding1 = bottom_fillet, rounding2 = top_fillet,
            anchor = BOTTOM);

        // Finger-retention grooves — rounded channels for secure grip
        for (i = [0 : groove_count - 1])
            rotate([0, 0, i * 360 / groove_count])
                translate([cap_od/2 - groove_depth + groove_cutter_r, 0, 0])
                    hull() {
                        translate([0, 0, groove_bottom + groove_cutter_r])
                            sphere(r = groove_cutter_r, $fn = 36);
                        translate([0, 0, groove_top - groove_cutter_r])
                            sphere(r = groove_cutter_r, $fn = 36);
                    }
    }
}

// ========================
// MAIN: FULL CAP
// ========================

module cap_body() {
    $slop = 0;  // We handle slop per-thread below

    difference() {
        // ── Solid exterior ──
        cap_exterior(total_height);

        // ── Zone 1: Smooth bore (bottom 5mm) ──
        // O-ring on battery body seals against this surface.
        // Must be smooth and dimensionally accurate.
        translate([0, 0, -0.01]) {
            cylinder(d = smooth_bore_id, h = nestout_smooth_zone + 0.02);

            // Lead-in chamfer at very bottom
            cylinder(
                d1 = smooth_bore_id + bottom_chamfer * 2,
                d2 = smooth_bore_id,
                h  = bottom_chamfer
            );
        }

        // ── Zone 2: Nestout threaded bore (upper 5mm of engagement) ──
        // Trapezoidal thread, coarse pitch, ~2 turns
        translate([0, 0, nestout_smooth_zone]) {
            $slop = nestout_slop;
            trapezoidal_threaded_rod(
                d       = nestout_thread_id,
                l       = nestout_thread_zone + 0.1,
                pitch   = nestout_pitch,
                thread_angle = thread_angle,
                internal = true,
                anchor   = BOTTOM
            );
        }

        // ── Zone 3: Transition (short taper from thread bore to cavity) ──
        translate([0, 0, nestout_engagement - 0.01])
            cylinder(
                d1 = smooth_bore_id + 1.0,
                d2 = cavity_id,
                h  = transition_height + 0.02
            );

        // ── Zone 4: Shaft clearance (gland shaft protrudes here) ──
        translate([0, 0, nestout_engagement + transition_height - 0.01])
            cylinder(
                d = cavity_id,
                h = cavity_height + 0.02
            );

        // ── Zone 5: M25 × 1.5 threaded bore (top plate) ──
        // Gland shaft threads into this from above
        translate([0, 0, nestout_engagement + transition_height + cavity_height - 0.01]) {
            $slop = m25_slop;
            threaded_rod(
                d        = m25_bore_id,
                l        = top_plate_height + 0.02,
                pitch    = m25_pitch,
                internal = true,
                anchor   = BOTTOM
            );
        }

        // ── Top chamfer (thread lead-in for gland) ──
        translate([0, 0, total_height - top_chamfer])
            cylinder(
                d1 = m25_bore_id,
                d2 = m25_bore_id + top_chamfer * 2,
                h  = top_chamfer + 0.01
            );
    }
}


// ========================
// CROSS-SECTION VIEW (for visualization)
// ========================

module cross_section() {
    difference() {
        cap_body();
        translate([0, -100, -1])
            cube([200, 200, 200]);
    }
}


// ========================
// RENDER
// ========================

cap_body();

//cross_section();
