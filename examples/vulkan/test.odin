package main

import "core:fmt"

import vk "./generated"

VulkanContext :: struct {
    instance : vk.Instance,
}

main :: proc() {
    vkc : VulkanContext;

    create_instance(&vkc);

    vk.destroy_instance(vkc.instance, nil);
}

// Create a vulkan Instance
create_instance :: proc(vkc : ^VulkanContext) {
    // @todo Enable validation layers?

    // Application info
    applicationInfo : vk.ApplicationInfo;
    applicationInfo.sType = vk.StructureType.ApplicationInfo;
    applicationInfo.pApplicationName = "vulkan-test";
    applicationInfo.pEngineName = "odin-binding-generator";
    applicationInfo.apiVersion = vk.API_VERSION_1_1;

    // Instance info
    instanceCreateInfo : vk.InstanceCreateInfo;
    instanceCreateInfo.sType = vk.StructureType.InstanceCreateInfo;
    instanceCreateInfo.pApplicationInfo = &applicationInfo;

    result := vk.create_instance(&instanceCreateInfo, nil, &vkc.instance);
    if result == vk.Result.Success {
        fmt.println("Successfully created instance!");
    }
    else {
        fmt.println("Unable to create instance!");
    }
}
