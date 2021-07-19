# frozen_string_literal: true

Synvert::Rewriter.new 'octopus', 'convert_to_rails_6' do
  description <<~EOS
    Convert octopus to rails 6 multi databases.

    ```ruby
    messages = current_user.using(:slave).messages
    ```

    =>

    ```ruby
    messages = ActiveRecord::Base.connected_to(role: :reading) do
      current_user.messages
    end
    ```
  EOS

  within_files 'app/**/*.rb' do
    %w[ivasgn lvasgn or_asgn].each do |type|
      with_node type: type do
        indent = ' ' * node.indent
        goto_node :right_value do
          using_node = nil
          with_node type: 'send', receiver: { not: nil }, message: 'using', arguments: [:slave] do
            using_node = node
            delete :dot, :message, :parentheses, :arguments
          end
          with_node type: 'send', receiver: { type: 'send', receiver: nil, message: 'using', arguments: [:slave] } do
            using_node = node
            delete :dot
            goto_node :receiver do
              delete :message, :parentheses, :arguments
            end
          end
          if using_node
            insert "ActiveRecord::Base.connected_to(role: :reading) do\n#{indent}  ", at: 'beginning'
            insert "\n#{indent}end", at: 'end'
          end
        end
      end
    end

    %w[def defs].each do |type|
      with_node type: type do
        goto_node :body do
          with_direct_node type: 'send' do
            indent = ' ' * node.indent
            using_node = nil
            with_node type: 'send', receiver: { not: nil }, message: 'using', arguments: [:slave] do
              using_node = node
              delete :dot, :message, :parentheses, :arguments
            end
            with_node type: 'send', receiver: { type: 'send', receiver: nil, message: 'using', arguments: [:slave] } do
              using_node = node
              delete :dot
              goto_node :receiver do
                delete :message, :parentheses, :arguments
              end
            end
            if using_node
              insert "ActiveRecord::Base.connected_to(role: :reading) do\n#{indent}  ", at: 'beginning'
              insert "\n#{indent}end", at: 'end'
            end
          end
        end
      end
    end
  end
end
