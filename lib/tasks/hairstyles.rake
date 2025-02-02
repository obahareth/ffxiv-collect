namespace :hairstyles do
  desc 'Create the hairstyles'
  task create: :environment do
    PaperTrail.enabled = false

    puts 'Creating hairstyles'

    count = Hairstyle.count

    XIVData.sheet('CharaMakeCustomize', raw: true).each do |custom|
      next if custom['HintItem'] == '0'
      item = Item.find_by(id: custom['HintItem'])
      next unless item.present? && item.name_en.match?('Aesthetics')

      data = { id: custom['Data'] }

      # Set the Hairstyle name to the item name sans the "Modern Aesthetics"
      %w(en de fr ja).each do |locale|
        data["name_#{locale}"] = sanitize_name(item["name_#{locale}"])
          .gsub(/.*(?:- |:|“(?=\w))(.*)/, '\1')
          .delete('“”')
      end

      data.merge!(item.slice(:description_en, :description_de, :description_fr, :description_ja))
      data[:item_id] = item.id.to_s if item.tradeable?

      if existing = Hairstyle.find_by(id: data[:id])
        existing.update!(data) if updated?(existing, data)
      else
        Hairstyle.create!(data)
      end

      # Create the hairstyle images
      path = Rails.root.join('public/images/hairstyles', custom['Data'])
      Dir.mkdir(path) unless Dir.exist?(path)

      output_path = path.join("#{custom['Icon']}.png")
      create_image(nil, XIVData.icon_path(custom['Icon'], hd: true), output_path)

      # Use the first image as a sample of the hairstyle
      sample_path = Rails.root.join('public/images/hairstyles/samples', "#{custom['Data']}.png")
      FileUtils.cp(output_path, sample_path) unless File.exists?(sample_path)
    end

    # Create the Eternal Bonding hairstyle which lacks an item unlock
    Hairstyle.find_or_create_by!(id: 228, patch: '2.4', name_en: 'Eternal Bonding', name_de: 'Eternal Bonding',
                                 name_fr: 'Eternal Bonding', name_ja: 'Eternal Bonding')

    create_hair_spritesheets

    puts "Created #{Hairstyle.count - count} new hairstyles"
  end
end
