# Godot Engine Behaviour Tree Editor Plugin

A Behavior Tree implementation for the Godot Engine, written in pure GDScript.

This project is a Godot Engine addon that adds a collection of nodes to the editor that facilitate the implementation of Behavior Trees. It is released under the terms of the MIT License.

This is a fork from Jeff Olson (https://github.com/olsonjeffery/behv_godot), which is itself based on ideas/concepts from `quabug/godot_behavior_tree`.

# Installation

1. Clone this repository
2. Copy the `addons/com.brandonlamb.bt` folder into your `res://addons` folder
3. In your project settings, enable the plugin
4. Add a BehaviourTree node to a scene
5. Call the `tick(actor, ctx)` function from `_process` or `_fixed_process`

# Design philosophy

- Easy to use and reason about - just Behavior Trees!
- Unobtrusive - to integrate an existing workflow
  - the BT primitives are implemented as Nodes that get added directly onto a scene; Actions are just normal nodes that you extend with a script
  - Build out a tree and attach it to your actor/entity sprite and just call `.tick()` during `_process()` or `_fixed_process()`
  - Uses a simple `Dictionary` value as the context object
- Add add little as possible to Godot -
  - The system uses existing numeric constants (`OK`, `FAILED` and `ERR_BUSY`) as stand-ins for the existing "Success, Failure, Running" concepts in BT.
  - The entire thing is implemented as a pure-GDScript addon that can be easily added to a project without having to rebuild the Godot editor

# State Values

* `OK`: returned when a criterion has been met by a condition node or an action node has been completed successfully;
* `FAILED`: returned when a criterion has not been met by a condition node or an action node could not finish its execution for any reason;
* `ERR_BUSY`: returned when an action node has been initialized but is still waiting the its resolution.
* `BehaviourError`: returned when some unexpected error happened in the tree, probably by a programming error (trying to verify an undefined variable). Its use depends on the final implementation of the leaf nodes.

# Node types

## BehaviourTree

Place this at the root of your tree at the AI/agent level. The `BehaviourTree` node accepts only a *single child* node. For example, you would probably add some kind of composite such as a `BehaviourSequence` node.

From a code perspective, this is a very simple node intended to be the root / entry-point to your behaviour tree logic. The `BehaviourTree` will simply call down to its child's `tick(actor, ctx)` function recursively.

## Composite Types

Composite nodes can have one or more children. The node is responsible to propagate the tick signal to its children, respecting some order. A composite node also must decide which and when to return the state values of its children, when the value is `OK` or `FAILED`. Notice that, when a child returns `ERR_BUSY` or `BehaviourError`, the composite node must return the state immediately. All composite nodes are represented graphically as a white box with a certain symbol inside.

### BehaviorSequence

A `BehaviourSequence` node runs a collection of child nodes, stopping at the first failure or `ERR_BUSY`.

The `BehaviourSequence` node ticks its children sequentially until one of them returns `FAILED`, `ERR_BUSY` or `BehaviourError`. If all children return the success state, the sequence also returns `OK`.

  - Will return and complete if any child returns `FAILED`, returning `FAILED`
  - Will return `OK` if all children return `OK`
  - Will return if any child returns `ERR_BUSY`. Will resume at the `ERR_BUSY`-returning child

### BehaviorSelector

A `BehaviourSelector` node runs a collection of child nodes, stopping at the first success or `ERR_BUSY`.

The `BehaviourSelector` node ticks its children sequentially until one of them returns `OK`, `ERR_BUSY` or `FAILED`. If all children return the failure state, the priority also returns `FAILED`.

For instance, suppose that a cleaning robot have a behavior to turn itself off. When the robot tries to turn itself off, the first action is performed and the robot tries to get back to its charging dock and turn off all its systems, but if this action fail for some reason (e.g., it could not find the dock) an emergency shutdown will be performed.

  - Will return and complete if any child returns `OK`, returning `OK`
  - Will return `FAILED` if all children return `FAILED`
  - Will return if any child returns `ERR_BUSY`. Will resume at the `ERR_BUSY`-returning child

## Decorator Types

Decorators are special nodes that can have only a single child. The goal of the decorator is to change the behavior of the child by manipulating the returning value or changing its ticking frequency. For example, a decorator may invert the result state of its child, similar to the NOT operator, or it can repeat the execution of the child for a predefined number of times. The figure below shows an example of the decorator "Repeat 3x", which will execute the action "ring bell" three times before returning a state value.

### Failer

The `BehaviourFailer` decorator is the inverse of `BehaviourSuceeder`, this decorator return `FAILED` for any child result.

### Inverter

The `BehaviourInverter` decorator negates the result of its child node, i.e., `OK` state becomes `FAILED`, and `FAILED` becomes `OK`. Notice that, inverter does not change `ERR_BUSY` or `BehaviourError` states.

### Limiter

The `BehaviourLimiter` decorator imposes a maximum number of calls its child can have within the whole execution of the Behavior Tree, i.e., after a certain number of calls, its child will never be called again.

### Max Time

The `BehaviourMaxTime` decorator limits the maximum time its child can be running. If the child does not complete its execution before the maximum time, the child task is terminated and a failure is returned, as shown algorithm below.

### Repeater

The `BehaviourRepeater` decorator sends the tick signal to its child every time that its child returns a `OK` or `FAILED` value, or when this decorator receives the tick. Additionally, a maximum number of repetition can be provided.

### Repeat Until Failed

The `BehaviourRepeatUntilFailed` decoroat keeps calling its child until the child returns a `FAILED` value. When this happen, the decorator return a `OK` state.

### Repeat Until Succeed

Similar to the `BehaviourRepeatUntilFailed` decorator, the `BehaviourRepeatUntilSucceed` decorator calls the child until it returns a `OK`.

### Succeeder

The `BehaviourSucceeder` is a decorator that returns `OK` always, no matter what its child returns. This is specially useful for debug and test purposes.

## Leaf Types

Leaf nodes are the primitive building blocks of behavior trees. These nodes do not have any children and therefore do not propagate the tick signal. These nodes perform some computation and return a state value. There are two types of leaf nodes (conditions and actions) and are categorized by their responsibility.

### Action

`BehaviourAction` nodes perform computations to change the actor state. The actions implementation depends on the actor type, e.g., the actions of a robot may involve sending motor signals, sending sounds through speakers or turning on lights, while the actions of a NPC may involve executing animations, performing spacial transformations, playing a sound, etc.

Actions may not be only external (i.e, actions that changes the environment as result of changes on the agent), they can be internal too, e.g., registering logs, saving files, changing internal variables, etc.

An action returns `OK` if it could be completed; returns `FAILED` if, for any reason, it could not be finished; or returns `ERR_BUSY` while executing the action.

### Condition

`BehaviourCondition` nodes check whether a certain condition has been met or not. In order to accomplish this, the node must have a target variable (e.g. a perception information such as "obstacle distance" or "other agent visibility"; or an internal variable such as "battery level" or "hungry level"; etc.) and a criteria to base the decision (e.g.: "obstacle distance > 100m?" or "battery power < 10%?").

These nodes return `OK` if the condition has been met and `FAILED` otherwise. Notice that, conditions do not return `ERR_BUSY` nor change values of system.

# Links

* https://github.com/olsonjeffery/behv_godot
* https://github.com/quabug/godot_behavior_tree
* http://blog.renatopp.com/2014/07/25/an-introduction-to-behavior-trees-part-1/
* http://blog.renatopp.com/2014/08/10/an-introduction-to-behavior-trees-part-2/
* http://blog.renatopp.com/2014/08/10/an-introduction-to-behavior-trees-part-3/
