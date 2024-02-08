# ANR experts
# author: @sardinecan
# date: 2022-12
# description: this Julia script creates collection and sends files via the Nakala API
# licence: CC-0

# @todo : gestion des erreurs (réponses server) ?
# @todo : écrire un fichier de log pour récupérer les identifiants des ressources crées.

#%% Upload datas
# alt + enter (⌥ + ↵) to execute cells
using CSV
using DataFrames
using HTTP
using JSON
using Dates

path = @__DIR__ # chemin vers le dossier courant
parentDir = dirname(path)

# identifiants
credentials = CSV.read(joinpath(parentDir,"credentials", "credentials.csv"), DataFrame, header=1) #liste des utilisateurs
user = "tnakala" #choix de l'utilisateur (api test = tnakala)
usrCredentials = filter(:user => n -> n == user, credentials) #récupération des identifiants
apiKey = usrCredentials[1, :apikey] #clé API

# API Nakala
apitest = true

if apitest == true
  apiurl = "https://apitest.nakala.fr"
else
  apiurl = "https://api.nakala.fr" 
end

filesUrl = joinpath(apiurl, "datas", "uploads")
metadataUrl = joinpath(apiurl, "datas")

include("listFile.jl") # un script qui crée, pour chaque sous-dossier, la liste des images à envoyer.
directories
for directory in directories

  files2upload = CSV.read(joinpath(path, directory, "files.csv"), DataFrame, header=1) # fichier de métadonnées 

  #%% Dépôt des fichiers
  files = Vector()
  filesInfo = []
  for (i, row) in enumerate(eachrow(files2upload))
    filename = row[:filename]
    
    println("Envoi du fichier n°", i, " - ", filename)

    headers = Dict(
      "X-API-KEY" => apiKey, 
      :accept => "application/json"
    )
    
    file = open(joinpath(path, directory, filename), "r")
    body = HTTP.Form(Dict(:file => file))

    fileUpload = HTTP.post(filesUrl, headers, body)
    fileResponse = JSON.parse(String(HTTP.payload(fileUpload)))
    fileIdentifier = fileResponse["sha1"]
    println(fileIdentifier)

    push!(files, fileResponse) # récupération de l'identifiant Nakala du fichier (fileIdentifier) pour le dépot des métadonnées et de la ressource
    push!(filesInfo, [filename, fileIdentifier])
  end

  # métadonnées de la ressource
  meta = Vector()

  metadata = CSV.read(joinpath(path, directory, "metadata.csv"), DataFrame, header=1) # fichier de métadonnées 

  metadata[!, :collections][1] !== missing  ? collections = split(metadata[!, :collections][1], ";") : collections = nothing
  authors = split(metadata[!, :authors][1], ";")
  date = metadata[!, :date][1]
  license = metadata[!, :licence][1]
  status = metadata[!, :status][1]
  datatype = metadata[!, :datatype][1]
  description = metadata[!, :description][1]
  lang = metadata[!, :lang][1]

  metadata[!, :collections][1] !== missing  ? keywords = split(metadata[!, :keywords][1], ";") : keywords = nothing
  
  metadata[!, :collections][1] !== missing  ? datarights = split(metadata[!, :rights][1], ";") : datarights = nothing
  lang = metadata[!, :lang][1]

  # titre (obligatoire)
  metaTitle = Dict(
    :value => directory,
    :typeUri => "http://www.w3.org/2001/XMLSchema#string",
    :propertyUri => "http://nakala.fr/terms#title",
    :lang => lang

  )
  push!(meta, metaTitle)

  # datatype (obligatoire)
  metaType = Dict(
    :value => datatype,
    :typeUri => "http://www.w3.org/2001/XMLSchema#anyURI",
    :propertyUri => "http://nakala.fr/terms#type"
  )
  push!(meta, metaType)

  # authorité/creator (obligatoire, mais accepte la valeur null)
  for author in authors   
    if length(split(author, ",")) > 1
      identity = split(author, ",")
      metaAuthor = Dict(
        :value => Dict(
          :givenname => identity[2],
          :surname => identity[1]
        ),
        :propertyUri => "http://nakala.fr/terms#creator"
      )
      push!(meta, metaAuthor)
    else
      metaAuthor = Dict(
        :value => Dict(
          :givenname => author,
          :surname => author
        ),
        :propertyUri => "http://nakala.fr/terms#creator"
      )
      push!(meta, metaAuthor)
    end
  end

  # date (obligatoire, mais accepte la valeur null)    
  metaCreated = Dict(
    :value => Dates.today(),
    :typeUri => "http://www.w3.org/2001/XMLSchema#string",
    :propertyUri => "http://nakala.fr/terms#created"
  )
  push!(meta, metaCreated)
    
  # licence (obligatoire pour une donnée publiée)
  metaLicense = Dict(
    :value => license,
    :typeUri => "http://www.w3.org/2001/XMLSchema#string",
    :propertyUri => "http://nakala.fr/terms#license"
  )
  push!(meta, metaLicense)

  # Droits (facultatif)
  rights = []
  if datarights !== nothing
    for dataright in datarights
      right = Dict(
        :id => split(dataright, ",")[1],
        :role => split(dataright, ",")[2]
      )
      push!(rights, right)
    end
  end

  # Description (facultatif)
  metaDescription = Dict(
    :value => description,
    :lang => lang,
    :typeUri => "http://www.w3.org/2001/XMLSchema#string",
    :propertyUri => "http://purl.org/dc/terms/description"
  )
  push!(meta, metaDescription)

  # Mots-clés
  if keywords !== nothing
    for keyword in keywords
      metaKeyword = Dict(
        :value => keyword,
        :lang => lang,
        :typeUri => "http://www.w3.org/2001/XMLSchema#string",
        :propertyUri => "http://purl.org/dc/terms/subject"
      )
      push!(meta, metaKeyword)
    end
  end

  # assemblage des métadonnées avant envoi de la ressource
  postdata = Dict(
    :collectionsIds => collections,
    :status => "pending",
    :files => files,
    :metas => meta,
    :rights => rights
  )
  println(JSON.json(postdata))

  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )
   
  metadataUpload = HTTP.request("POST", metadataUrl, headers, JSON.json(postdata))
  metadataResponse = JSON.parse(String(HTTP.payload(metadataUpload))) # réponse du server
  metadataId = metadataResponse["payload"]["id"] # récupération de l'identifiant Nakala de la ressource (identifier)
    
  println(metadataId)

  if isfile(joinpath(path, "datasUploaded.csv"))
    f = open(joinpath(path, "datasUploaded.csv"), "a")       
      write(f, "\n"*directory*","*metadataId)
    close(f)      
  else
    touch(joinpath(path, "datasUploaded.csv"))
    f = open(joinpath(path, "datasUploaded.csv"), "w") 
      write(f, "ressource,identifiant")
      write(f, "\n"*directory*","*metadataId)
    close(f)
  end

  
  touch(joinpath(path, directory, directory*".csv"))
  f = open(joinpath(path, directory, directory*".csv"), "w") 
    write(f, "filename,identifier,fileIdentifier")
    for file in filesInfo
      write(f, "\n"*file[1]*","*metadataId*","*file[2])
    end
  close(f)
end