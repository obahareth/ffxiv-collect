module ModHelper
  def change_diff(change)
    if change.event == 'create' && change.item_type == 'Source'
      changes = JSON.parse(change.object_changes)
      "#{changes['related_type'].last}: #{changes['text'].last}"
    elsif change.event == 'destroy' && change.item_type == 'Source'
      object = JSON.parse(change.object)
      "#{object['related_type']}: #{object['text']}"
    elsif change.event == 'update'
      list = JSON.parse(change.object_changes).map do |column, diff|
        if column
          "#{column}: #{diff.first} → #{diff.last}"
        end
      end

      list.join('<br>').html_safe
    end
  end

  def change_event(change)
    clazz = case(change.event)
            when 'create' then 'text-success'
            when 'update' then 'text-primary'
            when 'destroy' then 'text-danger'
            end

    content_tag :span, change.event, class: clazz
  end

  def change_link(change)
    if change.item_type == 'Source'
      url = polymorphic_url([:mod, change.collectable_type.downcase], id: change.collectable_id, action: :edit)
    else
      url = polymorphic_url([:mod, change.item_type.downcase], id: change.item_id, action: :edit)
    end

    link_to fa_icon('pencil'), url, class: 'btn btn-secondary btn-sm'
  end

  def change_type(change)
    [change.collectable_type, change.item_type].compact.join('/')
  end
end
