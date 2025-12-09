# Procedural-Aging

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

## Profiling