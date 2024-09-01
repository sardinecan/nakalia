# ANR experts
# author: @sardinecan
# date: 2024-05-25
# description: collection of functions for the nakalia notebook.
# licence: CC-0

# @todo : gestion des erreurs (réponses server) ?
# @todo : écrire un fichier de log pour récupérer les identifiants des ressources crées.

localARGS = isdefined(Base, :newARGS) ? newARGS : ARGS
@show localARGS
apikey = localARGS

function authorSearch()
  url = joinpath(apiurl, "authors/search")
  headers = Dict(
    "X-API-KEY" => "01234567-89ab-cdef-0123-456789abcdef",
    "Content-Type" => "application/json"
  )

  body = Dict(
    "q" => "morvan"
  )

  getAuthorsSearch = HTTP.request("GET", url, headers, body)
  response = JSON.parse(String(HTTP.payload(getAuthorsSearch)))
  return response
end

authorSearch()

#=
postCollection : cette fonction crée une collection
@arg collectionName : nom de la collection
@return : réponse du serveur avec id de la collection
=#
function postCollection(collectionName::String)
  url = joinpath(apiurl, "collections")
  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )

  body = Dict(
    :status => "private",
    :metas =>  [Dict(
      :value => collectionName,
      :propertyUri => "http://nakala.fr/terms#title",
      :typeUri => "http://www.w3.org/2001/XMLSchema#string",
      :lang => "fr"
    )]
  )

  # postCollectionQuery = HTTP.request("POST", url, headers, JSON.json(body)) # envoi des données pour la création de la collection
  # response = JSON.parse(String(HTTP.payload(postCollectionQuery))) # réponse du server
  # collectionId = collectionResponse["payload"]["id"] # récupération de l'id de la collection
  
  # return response
  try
    # Envoi de la requête HTTP POST
    postCollectionQuery = HTTP.request("POST", url, headers, JSON.json(body))

    #=== Vérification du code de statut de la réponse
    status_code = HTTP.status(postCollectionQuery)
    if status_code < 200 || status_code >= 300
        error("Failed to create collection: HTTP status $status_code")
    end
    ===#

    response = JSON.parse(String(HTTP.payload(postCollectionQuery)))
    return response

catch e
    # Gestion spécifique des erreurs HTTP
    if isa(e, HTTP.ExceptionRequest.StatusError)
        return "Request failed with status code $(e.status): $(e.response)"
    else
        # Gestion des autres types d'erreurs
        return "An unexpected error occurred: $(e)"
    end
end
end

#=
postDatasToCollection : cette fonction lie des données à une collection
@arg collectionIdentifier : identifiant de la collection
@arg datas : un array comportant les identifiants des données à lier
@return : réponse du serveur
=#
function postDatasToCollection(collectionIdentifier::String, datas::Vector)
  url = joinpath(apiurl, "collections", collectionIdentifier, "datas")

  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )
  
  body = datas
  
  postDatasToCollectionQuery = HTTP.request("POST", url, headers, JSON.json(body)) # ajoute les données listées ci-dessus à une collection
  response = JSON.parse(String(HTTP.payload(postDatasToCollectionQuery))) # réponse du server

  return response
end

#=
deleteDataFromCollectionQuery : retire des données d'une collection
@arg collectionIdentifier : identifiant de la collection
@arg datas : un array comportant les identifiants des données à retirer
@return : réponse du serveur
=#
function deleteDatasFromCollection(collectionIdentifier::String, datas::Vector)
  url = joinpath(apiurl, "collections", collectionIdentifier, "datas")

  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )
  
  body = datas
  
  deleteDataFromCollectionQuery = HTTP.request("DELETE", url, headers, JSON.json(body)) # supprime les données listées plus haut de la collection
  response = JSON.parse(String(HTTP.payload(deleteDataFromCollectionQuery))) # réponse du server

  return response
end

#=
getUserInfo : liste les données utilisateur
@return réponse serveur (Dict)
=#
function getUserInfo()
  url = joinpath(apiurl, "users", "me")

  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )

  getUserInfoQuery = HTTP.request("GET", url, headers)
  response = JSON.parse(String(HTTP.payload(getUserInfoQuery))) # réponse du server
  
  return response
end

#=
postUserDatas : récupération des données d'un utilisateur
@arg scope (facultatif) : périmètre des données
@arg status (facultatif) : status des données
@arg titleSearch (facultatif) : titre pour portion de titre
@return réponse serveur (Dict de la donnée)
=#
function postUserDatas(scope::String="all", status::Vector=[], titleSearch::String="")
  url = joinpath(apiurl, "users", "datas", scope)
  
  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )
    
    #=
    body = Dict(
      :page => 1,
      :limit => 100,
      :orders => [
        "creDate,desc"
      ],
      :types: => [
        "http://purl.org/coar/resource_type/c_c513"
      ],
      :status => [
        "published"
      ],
      :createdYears => [
        "2023"
      ],
      :collections => [
        "11280/9f85fbd6"
      ],
      :titleSearch => "",
      :titleSearchLang => "fr",
      :orderLang => "fr"
    )
    =#
    
  body = Dict{Symbol, Any}(
    :page => 1,
    :limit => 250
  )

  statusParameter = Dict(
    :status => status
  )
  length(status) == 0 ? Nothing : merge!(body, statusParameter) # fusionne les dict body et statusParameter si ce paramètre est renseigné

  titleSearchParameter = Dict(
    :titleSearch => titleSearch
  )
  titleSearch == "" ? Nothing : merge!(body, titleSearchParameter) # fusionne les dict body et titleSearchParameter si ce paramètre est renseigné
    
  postUserDatas = HTTP.request("POST", url, headers, JSON.json(body))
  response = JSON.parse(String(HTTP.payload(postUserDatas))) # réponse du server

  return response
end

#=
putDataStatus : modifie le statut d'une donnée
@arg dataIdentifier : identifiant de la donnée
@arg newStatus : nouveau statut de la donnée
=#
function putDataStatus(dataIdentifier::String, newStatus::String)
  url = joinpath(apiurl, "datas", dataIdentifier, "status", newStatus)
  
  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )
    
  putDataStatusQuery = HTTP.put(url, headers)
  #response = JSON.parse(String(HTTP.payload(putDataStatusQuery))) # réponse du server 
  
  return putDataStatusQuery
end

#=
getDatasResume : résumé d'un jeu de donnée
@arg datas : un array de dictionnaires de données nakala
@return un array de dict titre => identifiant
=#
function getDatasResume(datas::Vector{Any})
  list = Vector()
  for data in datas
  
    identifier = get(data, "identifier", "")
    metas = get(data, "metas", "")
    
    title = filter(x -> get(x, "propertyUri", "") == "http://nakala.fr/terms#title", metas)[1]

    item = Dict(
      get(title, "value", "noTitle") => identifier
    )
    push!(list, item)
  end

  return list
end

#=
downloadFiles télécharge les fichiers d'une donnée
@arg data : les métadonnées d'une donnée nakala
@arg path : emplacement de la sauvegarde

@return : télécharge les fichiers et retourne la liste des urls de téléchargement
=#
function downloadFiles(data::Dict, path::String)
    identifier = get(data, "identifier", "")
    filesList = get(data, "files", "")
    metadata = get(data, "metas", "")
    title = get(metadata, "title", "")

  
    isdir(joinpath(path, title)) ? Nothing : mkdir(joinpath(path, title)) #création d'un dossier correspondant au titre de la donnée

    urls = Vector()
    for file in filesList
        fileIdentifier = get(file, "sha1", "")
        filename = get(file, "name", "")
  
        fileUrl = joinpath(apiurl, "data", identifier, fileIdentifier)
  
        img = download(fileUrl) |> load
        save(joinpath(path, title, filename), rot180(img))

        push!(urls, fileUrl)
    end
 
    return urls
end

#=
getFilesUrlFromData : recherche un fichier dans un donnée et retourne son url de téléchargement
@arg data : métadonnée d'une donnée Nakala
@arg filename : le fichier à rechercher dans la donnée

@return url de téléchargement
=#
function getFilesUrlFromData(data::Dict, filenames::Vector)
    identifier = get(data, "identifier", "")
    filesList = get(data, "files", "")

    urls = Vector()
    for file in filenames
        item = filter(x -> get(x, "name", "") == file, filesList)[1]
        fileIdentifier = get(item, "sha1", "")
  
        fileUrl = joinpath(apiurl, "data", identifier, fileIdentifier)
        push!(urls, fileUrl)
    end

    return urls
end

#=
postFile : dépôt d'un fichier 
@arg file : chemin vers le fichier à déposer

@return : réponse serveur contenant l'identifiant du fichier
=#
function postFile(file::String)
  url = joinpath(apiurl, "datas", "uploads")

  file = open(file, "r")

  headers = Dict(
    "X-API-KEY" => apiKey,
    :accept => "application/json"
  )
  
  body = HTTP.Form(Dict(:file => file))
  
  postFile = HTTP.post(url, headers, body)
  response = JSON.parse(String(HTTP.payload(postFile)))
  
  return response
end

#=
postFilesFromList : dépot de fichiers à partir d'un liste csv
@arg directoryPath : chemin vers le dossier contenant les fichiers à déposer et la liste

@return : array [ métadonnées des fichiers déposés ]
=#
function postFilesFromList(directoryPath::String)
  files2upload = CSV.read(joinpath(directoryPath, "files.csv"), DataFrame, header=1) # fichier de métadonnées 

  #%% Dépôt des fichiers
  files = Vector()
  filesInfo = []
  
  for (i, row) in enumerate(eachrow(files2upload))
    filename = row[:filename]
    
    println("Envoi du fichier n°", i, " - ", filename)
    fileResponse = postFile(joinpath(directoryPath, filename))
    fileIdentifier = fileResponse["sha1"]

    push!(files, fileResponse) # récupération de l'identifiant Nakala du fichier (fileIdentifier) pour le dépot des métadonnées et de la ressource
    push!(filesInfo, [filename, fileIdentifier])
  end
  
  return [files, filesInfo]
end

#=
postData : dépôt d'une donnée
@arg data : métadonnées de la donnée à déposer

@return réponse du serveur (dict)
=#
function postData(data::Dict)
  url = joinpath(apiurl, "datas")
  
  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )

  postData = HTTP.request("POST", url, headers, JSON.json(data))
  response = JSON.parse(String(HTTP.payload(postData))) # réponse du server

  return response
end

#=
metadataFromCsv : établissement des métadonnées d'une donnée à partir d'un fichier csv
@arg path : chemin vers le fichier de métadonnées
=#
function metadataFromCsv(path::String)
  metadata = CSV.read(path, DataFrame, header=1) # fichier de métadonnées 

  title = metadata[!, :title][1] 
  metadata[!, :collections][1] !== missing  ? collections = split(metadata[!, :collections][1], ";") : collections = nothing
  authors = split(metadata[!, :authors][1], ";")
  date = metadata[!, :date][1]
  license = metadata[!, :licence][1]
  status = metadata[!, :status][1]
  datatype = metadata[!, :datatype][1]
  description = metadata[!, :description][1]
  metadata[!, :collections][1] !== missing  ? keywords = split(metadata[!, :keywords][1], ";") : keywords = nothing
  metadata[!, :collections][1] !== missing  ? datarights = split(metadata[!, :rights][1], ";") : datarights = nothing
  lang = metadata[!, :lang][1]
  
  # métadonnées de la ressource
  meta = Vector()

  # titre (obligatoire)
  metaTitle = Dict(
    :value => title,
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
  body = Dict{Symbol, Any}(
    :collectionsIds => collections,
    :status => "pending"
    :metas => meta,
    :rights => rights
  )

  return body
end

#=
submitDataFromFolder : dépôt d'une donnée à partir d'un dossier contenant les fichiers constitutifs de la donnée et les métadonnées contenus dans un ficheir csv
@arg path : chemin vers le dossier contenant les données à déposer
@arg directory : nom du dossier constitutif de la donnée
=#
function submitDataFromFolder(path::String, directory::String)
  postedFilesFromList = postFilesFromList(joinpath(path, directory))
  files = Dict( :files => postedFilesFromList[1] )
  filesInfo = postedFilesFromList[2]

  metadata = metadataFromCsv(joinpath(path, directory, "metadata.csv"))

  merge!(metadata, files) 

  postedData = postData(metadata)
  dataIdentifier = postedData["payload"]["id"] # récupération de l'identifiant Nakala de la ressource (identifier)
  
  return dataIdentifier
  
  if isfile(joinpath(path, "datasUploaded.csv"))
    f = open(joinpath(path, "datasUploaded.csv"), "a")       
      write(f, "\n"*directory*","*dataIdentifier)
    close(f)      
  else
    touch(joinpath(path, "datasUploaded.csv"))
    f = open(joinpath(path, "datasUploaded.csv"), "w") 
      write(f, "ressource,identifiant")
      write(f, "\n"*directory*","*dataIdentifier)
    close(f)
  end

  
  touch(joinpath(path, directory, directory*".csv"))
  f = open(joinpath(path, directory, directory*".csv"), "w") 
    write(f, "filename,identifier,fileIdentifier")
    for file in filesInfo
      write(f, "\n"*file[1]*","*dataIdentifier*","*file[2])
    end
  close(f)
end

#=
listFile : liste le contenu d'un dossier et écrit un fichier files.csv dans chaque sous-dossier (donnée) comportant tous les fichiers à déposer pour chaque donnée
@arg path : chemin vers le dossier à lister

@return : la liste des dossiers correspondant aux données 
=#
function listFile(path)
  directories = []
  for (root, dirs, files) in walkdir(path)
    filter!(x -> startswith(x, ".") == false, dirs)
    for dir in dirs
      touch(joinpath(root, dir, "files.csv"))
      f = open(joinpath(root, dir, "files.csv"), "w")
        write(f, "filename")
      close(f)

      println(dir)
      push!(directories, dir)

      list = readdir(joinpath(root, dir))

      for file in list

        extentions = [".tiff", ".tif", ".jpg", "jpeg", ".png", ".txt"]
        for extention in extentions
          if endswith(lowercase(file), extention)
            f = open(joinpath(root, dir, "files.csv"), "a")
              write(f, "\n"*file)
            close(f)
          end
        end
      end

    end
  end
  
  return directories
end

#=
addFileToData ajout d'un fichier à une donnée
@arg dataIdentifier : identifiant de la données
@arg file : métadonnées du fichier récupérées depuis Nakala
=#
function addFileToData(dataIdentifier::String, file::Dict)
  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )

  fileIdentifier = get(file, "sha1", "")

  body = Dict(
    :sha1 => fileIdentifier
  )

  #=
  body = Dict()
    :sha1 => fileIdentifier,
    :description => "",
    :embargoed => ""
  )
  =#

  url = joinpath(apiurl, "datas", dataIdentifier, "files")
  
  addFile = HTTP.post(url, headers, JSON.json(body))
  response = JSON.parse(String(HTTP.payload(addFile)))

  return response
end