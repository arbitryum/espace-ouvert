module Seeds
  # Creates or updates sample coworking projects; never deletes anything.
  class Coworking
    PROJECTS = [
      {
        name: "Atelier numérique intergénérationnel",
        organization_name: "Les Liens du Canal",
        description: "Une équipe associative anime des ateliers numériques ouverts aux habitants et aux résidents.",
        location: "Paris 19e",
        care_home: "EHPAD Les Jardins du Canal",
        care_home_address: "12 avenue de Flandre, 75019 Paris",
        status: "active",
        published: true
      },
      {
        name: "Permanence d'accompagnement local",
        organization_name: "Maison des Initiatives",
        description: "Un collectif recherche un espace calme pour accueillir des permanences hebdomadaires de proximité.",
        location: "Montreuil",
        care_home: "Résidence Les Lilas",
        care_home_address: "8 rue de Paris, 93100 Montreuil",
        status: "seeking",
        published: true
      },
      {
        name: "Projet à préparer",
        organization_name: "Collectif Horizon",
        description: "Ce projet est conservé comme exemple de brouillon et n'est pas encore visible publiquement.",
        location: "Lyon",
        care_home: "Maison de retraite Horizon",
        care_home_address: "4 rue des Écoles, 69007 Lyon",
        status: "draft",
        published: false
      }
    ].freeze

    def self.run(output: $stdout)
      PROJECTS.each do |attributes|
        care_home = CareHome.create_with(address: attributes[:care_home_address]).find_or_create_by!(name: attributes[:care_home])
        project = CoworkingProject.find_or_initialize_by(name: attributes[:name])
        output.puts "#{project.new_record? ? 'Created' : 'Updated'}: #{project.name}"
        project.update!(attributes.except(:name, :care_home, :care_home_address).merge(care_home:))
      end
      output.puts "#{CoworkingProject.count} coworking projects."
    end
  end
end
