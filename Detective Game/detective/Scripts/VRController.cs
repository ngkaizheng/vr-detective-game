using Godot;
using System;

public partial class VRController : XRController3D
{
	private Area3D grabArea; // Reference to Area3D node for detecting grabbable objects
	private RigidBody3D grabbedObject; // Currently grabbed object

	public override void _Ready()
	{
		// Connect ButtonPressed signal for debugging raw OpenXR inputs (optional)
		ButtonPressed += OnButtonPressed;

		// Get the Area3D node for grabbing (must be a child named "GrabArea")
		try
		{
			grabArea = GetNode<Area3D>("GrabArea");
		}
		catch (Exception e)
		{
			GD.PrintErr($"{Name}: Failed to find GrabArea node: {e.Message}");
		}
	}

	private void OnButtonPressed(string name)
	{
		GD.Print($"{Name}: Raw button pressed: {name}");
	}

	// private void OnButtonPressed(StringName button)
	// {
	// 	// Debug raw OpenXR button presses (optional, helps verify input names)
	// 	GD.Print($"{Name}: Raw button pressed: {button}");
	// }

	public override void _Process(double delta)
	{
		// Check for Trigger input action
		if (Input.IsActionJustPressed("Trigger"))
		{
			GD.Print($"{Name}: Trigger action pressed!");
			// Add trigger-related actions here (e.g., shooting, selecting)
		}

		// Check for Grip input action to grab or release objects
		if (Input.IsActionJustPressed("Grip"))
		{
			GD.Print($"{Name}: Grip action pressed!");
			if (grabbedObject == null)
			{
				TryGrab();
			}
			else
			{
				ReleaseObject();
			}
		}

		// Optional: Check analog trigger input for continuous control
		if (GetFloat("trigger") > 0.5f)
		{
			// Example: Handle partial trigger press (uncomment to use)
			// GD.Print($"{Name}: Trigger axis: {GetFloat("trigger")}");
		}
	}

	private void TryGrab()
	{
		if (grabArea == null)
		{
			GD.PrintErr($"{Name}: GrabArea is not set!");
			return;
		}

		// Get overlapping bodies in the Area3D
		var bodies = grabArea.GetOverlappingBodies();
		foreach (var body in bodies)
		{
			if (body is RigidBody3D rigidBody)
			{
				grabbedObject = rigidBody;
				// Reparent the object to the controller to "grab" it
				grabbedObject.Reparent(this);
				// Freeze physics to prevent unwanted movement
				grabbedObject.Freeze = true;
				GD.Print($"{Name}: Grabbed {grabbedObject.Name}");
				break; // Grab only the first valid object
			}
		}
	}

	private void ReleaseObject()
	{
		if (grabbedObject != null)
		{
			// Reparent back to the scene root
			grabbedObject.Reparent(GetTree().Root);
			// Unfreeze physics
			grabbedObject.Freeze = false;
			GD.Print($"{Name}: Released {grabbedObject.Name}");
			grabbedObject = null;
		}
	}
}
