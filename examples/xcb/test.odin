package main

import xcb "./generated"

import "core:fmt"
import "core:strings"

XcbContext :: struct {
    connection : ^xcb.Connection,
    screen : ^xcb.Screen,
}

main :: proc() {
    xcbc : XcbContext;

    create_connection(&xcbc);
    create_window(&xcbc);

    fmt.print("Window is open, focus it and type anything to try events.\n");
    for true {
        event := xcb.poll_for_event(xcbc.connection);
        if event != nil {
            shouldClose := process_event(event);
            if shouldClose do break;

            xcb.flush(xcbc.connection);
        }
    }

    fmt.print("Closing.\n");
}

// Initialize the XCB connection
create_connection :: proc(xcbc : ^XcbContext) {
    screenIndex : i32;
    xcbc.connection = xcb.connect(nil, &screenIndex);
    if (xcbc.connection == nil) {
        fmt.print("Could not create XCB connection.\n");
        return;
    }

    // Find the correct screen
    setup := xcb.get_setup(xcbc.connection);
    screenIterator := xcb.setup_roots_iterator(setup);
    for i : i32 = 0; i < screenIndex; i += 1 {
        xcb.screen_next(&screenIterator);
    }
    xcbc.screen = screenIterator.data;

    fmt.print("Created XCB connection.\n");
}

// Initialize the XCB window
create_window :: proc(xcbc : ^XcbContext) {
    // Our window id
    id := xcb.generate_id(xcbc.connection);

    // Build the window indeeds
    valueMask := cast(u32) (xcb.Cw.BackPixel | xcb.Cw.EventMask);
    valueList : [32]u32;

    valueList[0] = xcbc.screen.blackPixel;
    valueList[1] = cast(u32) (xcb.EventMask.PointerMotion | xcb.EventMask.KeyPress);
    valueList[2] = 0;

    xcb.create_window(xcbc.connection, 0, id, xcbc.screen.root, 0, 0, 800, 600, 0,
                      cast(u16) xcb.WindowClass.InputOutput, xcbc.screen.rootVisual, valueMask, &valueList[0]);

    // @fixme This does not work, reply is always nil, might be a low-level binding issue.
    // cookie := xcb.intern_atom(xcbc.connection, 0, len("WM_DELETE_WINDOW"), "WM_DELETE_WINDOW");
    // reply := xcb.intern_atom_reply(xcbc.connection, cookie, nil);

    // Show the final window
    xcb.map_window(xcbc.connection, id);
    xcb.flush(xcbc.connection);

	fmt.print("Created window.\n");
}

// Returns true when closing the application is asked.
process_event :: proc(event : ^xcb.GenericEvent) -> bool {
    eventType := (event.responseType & 0x7f);
    switch (eventType) {
    case xcb.MOTION_NOTIFY:
        motionNotifyEvent := cast(^xcb.MotionNotifyEvent) event;
        fmt.print("MotionNotify: (", motionNotifyEvent.eventX, ", ", motionNotifyEvent.eventY, ")\n");

    case xcb.KEY_PRESS:
        keyPressEvent := cast(^xcb.KeyPressEvent) event;
        fmt.print("KeyPress: ", keyPressEvent.detail, "\n");

        // Escape
        if keyPressEvent.detail == 9 do return true;
    }

    free(event);

    return false;
}
