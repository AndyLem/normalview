# File: my_extension.rb

module AndyLem
    module NormalView

      # Define a command class
      class NormalViewCommand

        class ClickObserver < Sketchup::ViewObserver
            def initialize(extension_command)
              @extension_command = extension_command
            end

            def onViewClick(view, x, y, flags, view_info)
                @extension_command.save_coordinates_for_view(view, x, y)
            end

            def onViewAdded(view)
              @extension_command.store_view(view)
            end
        end

        def self.store_view(view)
            @views ||= {}
            @views[view] = { x: nil, y: nil }
        end

        # Method to save coordinates (x, y) in the dictionary for the corresponding view
        def self.save_coordinates_for_view(view, x, y)
            @views ||= {}
            if @views.key?(view)
                @views[view][:x] = x
                @views[view][:y] = y
            end
        end

        # Method to execute when the menu item or toolbar button is clicked
        def self.perform
          begin

          # Get the active model
            model = Sketchup.active_model
            view = model.view

            if @views.key?(view)
                x = @views[view][:x]
                y = @views[view][:y]
            end
            return if x.nil?
            return if y.nil?

            picked_face = pick_face(x, y, view)

            # Check if a face was picked
            if picked_face && picked_face.is_a?(Sketchup::Face)
                # Get the normal vector of the picked face
                selected_face = picked_face
            else
                return
            end


        #   # Get the selection
        #   selection = model.selection

        #   # Check if there's at least one entity selected
        #   if selection.empty?
        #     # UI.messagebox('No face selected. Please select a face and try again.')
        #     # do nothing
        #     return
        #   end

        #     # Get the selection
        #     selection = model.selection

        #     # Find the first face in the selection
        #     selected_face = selection.find { |entity| entity.is_a?(Sketchup::Face) }

        #     # Check if a face was found
        #     if selected_face.nil?
        #         # UI.messagebox('No face selected. Please select a face and try again.')
        #         return
        #     end



            # Get the normal vector of the selected face
            normal_vector = selected_face.normal

            # Get the camera from the model
            camera = model.active_view.camera

            dist = selected_face.bounds.center - camera.eye
            long_norm = normal_vector.reverse.clone
            long_norm.length = dist.length

            eye = selected_face.bounds.center + long_norm
            target = selected_face.bounds.center
            up = camera.up
            my_camera = Sketchup::Camera.new eye, target, up

            # Set the camera eye position to be on the normal to the selected face
            #   camera.eye = selected_face.bounds.center - normal_vector
            #   camera.target =  normal_vector.reverse

            # Invalidate the view to see the change
            #   model.active_view.invalidate

            model.active_view.camera = my_camera
            # model.pages.selected_page.update(1)

          rescue Exception => e
              UI.messagebox(e)
          end

        end

        def pick_face(x, y, view)
            # Get the picking ray from the screen coordinates
            ray = view.pickray(x, y)

            # Get the model and active entities
            model = Sketchup.active_model
            entities = model.active_entities

            # Use the ray to intersect with entities and find the picked face
            picked_face = entities.raytest(ray.origin, ray.direction).first

            picked_face&.entity
        end

        def self.perform_up
            begin
                model = Sketchup.active_model
                camera = model.active_view.camera
                eye = camera.eye
                target = camera.target
                up = [0,0,1]
                my_camera = Sketchup::Camera.new eye, target, up
                model.active_view.camera = my_camera
            rescue Exception => e
                UI.messagebox(e)
            end
        end


      end # NormalViewCommand

      # Create the menu and toolbar
      def self.create_menu
        # Add a menu item to the Extensions menu
        menu = UI.menu('Extensions')
        menu.add_item('Normal View') {
          NormalViewCommand.perform
        }
        menu.add_item('View Up') {
          NormalViewCommand.perform_up
        }
        # Create a toolbar and add a button
        toolbar = UI::Toolbar.new('Normal View')
        cmd = UI::Command.new('Normal View') {
            NormalViewCommand.perform
        }
        cmd.small_icon = 'normal_view_64.ico' # Replace with the actual path
        cmd.large_icon = 'normal_view_64.ico' # Replace with the actual path
        cmd.tooltip = 'Normal View'
        # cmd.status_bar_text = 'Ctrl+X to run Normal View'
        toolbar = toolbar.add_item(cmd)

        cmd_up = UI::Command.new('View Up') {
            NormalViewCommand.perform_up
        }
        cmd_up.small_icon = 'normal_view_64.ico' # Replace with the actual path
        cmd_up.large_icon = 'normal_view_64.ico' # Replace with the actual path
        cmd_up.tooltip = 'View Up'
        toolbar = toolbar.add_item(cmd_up)


        toolbar.show

        # Register a hotkey (Control+Shift+Q)
        # UI.add_key_callback(['x', 'X'], UI::MODIFIER_CONTROL ) {
        #     NormalViewCommand.perform
        #   }

        command = NormalViewCommand.new()
        click_observer = ClickObserver.new(command)
        Sketchup.active_model.view.add_observer(click_observer)

      end

      # Method called when the extension is loaded
      def self.activate
        create_menu


      end

      # Method called when the extension is deactivated
      def self.deactivate
        # Code to handle deactivation, if needed
      end

    end # NormalView
  end # AndyLem

  # Call the activation method when the extension is loaded
  AndyLem::NormalView.activate
