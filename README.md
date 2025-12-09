# Procedural-Aging
TODO: Beyond just the shader, context and the project itself, also explain systems like vertex painting etc.

## Shaders
TODO: Explain shader config and different files

## Context Parameters
Beyond shader- and material-specific parameters, there are properties of objects and their environments themselves that also affect weathering.
Here, these are separated into:
- **local context**: Properties of an object instance (*age* and *paint stability* in the case of PMA-S). These are stored in object scripts and sent to the shader.
- **environment context**: Properties of the environment in which an object exists. These are stored using the **Context Probe** addon.

#### Context Probe Addon
This addon introduces three node classes:
1. **ContextParams**: A resource class that stores a set of environment context parameters and emits a "changed" signal whenever they are modified so that **ContextSampler** nodes can listen for it. For this prototype, only three parameters exist, but the class can easily be extended:
    - *uv_and_heat*: Combines both the UV intensity and heat intensity of the environment. It influences effects such as paint yellowing.
    - *pollution*: Dirt, toxicity, pathogens and other waste products in the environment. Influences grime deposition and surface discoloration.
    - *moisture*: Combines both air humidity and the frequency of exposure to water. Speeds up degradation and corrosion significantly.

    Together, they all influence the overall weathering intensity.
2. **ContextSampler**: A monitoring node that samples **ContextParams** from **ContextProbe**s that it intersects and emits signals whenever the sampled parameters change. Intended to be a child of a node that uses context-based shading. For multiple probes it averages their values, and for no probes it returns default **ContextParams**.
3. **ContextProbe**: An **Area3D** that stores **ContextParams**. 

A demo for the context probe system is provided. More information is in the demo section.

## Assets
While the actual prototype code provided with this repository is complete, the demo, profiling, and testing scenes all depend on CC licensed assets.
In the **releases** tab, the **Assets-1.0** release contains the asset directory, split into three *.tar* files.

Run
```
cat assets.tar.* | tar -xf -
```
at the root or the *procedural_aging* directory to unpack the asset directory with the correct path structure.
Once that is done, Godot should recognize and import all assets correctly.

The **CREDITS.md** file provides author and licensing information for all assets that were not made by me.
My own assets use the same license as this repository.

## Scenes and scripts
A variety of scenes are provided alongside the prototype code.

- **demos**: Scenes that demonstrate specific features
- **profiling**: Scenes that can be used to profile the performance of the prototype.
- **testing**: Scenes that were used in testing and development and may still be useful for understanding the interface.
- **visualizations**: Scenes that can be used for visualizing output and computation components of the shader, such as specific noise functions.

The script directories that correspond to these scenes contain utility code that may also be useful for understanding how the prototype interfaces with Godot.
In particular, *aging_object.gd* is a good example.

Beyond scene-specific scripts, there is also code related to **baking**, which is explained in its own section.

## Baking
While the focus of PMA-S is running in real-time, some code is also provided to allow saving the results to static textures.

The **AgeBaker** allows registering geometry instances along with the material that should be baked. Once bake() is called, all registered instances are baked at the same time and their materials are overwritten with shaders that display the baked textures.

Note that the given material needs to be in *BAKE_MODE* for this to work. More information on this is given in the shader section.

The *baked_aged_object* script also allows for exporting the textures to permanent storage.

## Demos
This project provides a few demo scenes for the appearance and infrastructure of PMA-S and the context-based shading system.
Some can be accessed through the main scene menu:
- **Shipyard**: An old shipyard. The user can walk through the scene and approach podiums with red buttons. If pressed (using the mouse after pressing *TAB* to toggle the UI), a menu opens up that allows dynamic modification of the weathered appearance of the object that the podium corresponds to. The intent of this demo is to show how the shader can integrate with "complex" scenes in real-time. Movement is controlled with *WASD* and *Shift* for faster walking. 
- **Single objects**: This demo allows modifying the weathered appearance of various objects. It is controlled entirely with the UI that is toggled with *TAB*. The parameters that can be edited here represent just a small selection. The Godot editor should be used to modify other parameters of the shader.
- **Context**: This demo showcases the **ContextProbe** system. With the use of *WASD*, *Shift*, and *Space* for movement, as well as the UI toggled with *TAB*, the user can see the effect of probes on varying amounts of object instances. To modify the probes themselves (both their parameters and their shapes/transforms), the scene needs to be run within the Godot editor. A system for visualizing probe areas in the run-time view is provided so that they can be matched up to what is being edited in the scene view, but it only supports spheres, cylinders and boxes. Other shapes can be used but do not have a run-time visualization.

The last demo can only be accessed within the Godot editor:
- **Vertex painting**: A sphere that uses vertex colors as weathering weights. Using the shader parameter editor, the effect of various vertex weight configurations can be seen. Modifying the vertex colors in the corresponding *vert_color_test.blend* file allows live changes to the vertex weight distribution.

## Profiling
The main menu has a button for **profiling**. From the main profiling scene, various subscenes can be opened and
modified to profile the performance of PMA-S (as well as the baked equivalent) under specific conditions.

The UI in the top left has input options that stay the same for all profiling scenes, such the scene picker itself, the shader picker, bake resolution, and more. It also contains a "Run suite" button. This disables vsync and the UI to run all profiling scenes in various configurations. The results are written to the default Godot user directory. This suite is only run for the selected shader (and, if baked, the selected resolution). To test different shaders and resolutions, the old results need to be saved and the suite re-run.

**NOTE**: The vsync button and the automatic vsync disabling of the profiling suite may not work depending on operating system restrictions. The user may have to take additional steps to allow running with an un-capped framerate.

The bottom left UI has options that are specific to the current scene:
- **rotating_object**: This scene weathers a rotating object (sphere or quad) over time. The menu allows adjusting the mesh and its triangle complexity.
- **multiple_objects**: This scene weathers multiple objects. The menu allows adjusting the layout and amount of objects. It also allows changing between **instanced** (uses MultiMeshInstance3D -> all instances share the same appearance) and **non-instanced** (all objects have a unique appearance).
- **pixel_count**: This scene weathers a quad at an adjustable distance from the camera to profile performance with respect to pixel count.
- **lights**: This scene allows profiling the shader with varying amounts of light sources.
- **parameters**: This scene is used by the automatic profiling suite only. It tests a quad at various shader parameter configurations but has no GUI of its own.