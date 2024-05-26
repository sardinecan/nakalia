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

function createCollection(collectionName::String)
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

  postCollection = HTTP.request("POST", url, headers, JSON.json(body)) # envoi des données pour la création de la collection
  collectionResponse = JSON.parse(String(HTTP.payload(postCollection))) # réponse du server
  collectionId = collectionResponse["payload"]["id"] # récupération de l'id de la collection
  
  return print("Identifiant de la collection : ", collectionId)
end

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

function downloadFiles(data::Dict, title::String)
    identifier = get(data, "identifier", "")
    filesList = get(data, "files", "")
  
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

function getFilesFromData(data, filenames)
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

function postFile(file)
  file = open(file, "r")

  headers = Dict(
    "X-API-KEY" => apiKey,
    :accept => "application/json"
  )
  
  body = HTTP.Form(Dict(:file => file))
  
  url = joinpath(apiurl, "datas", "uploads")
  
  postFile = HTTP.post(url, headers, body)
  response = JSON.parse(String(HTTP.payload(postFile)))
  
  return response
end

function postFilesFromList(directoryPath)
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

function postData(directory)
    postedFilesFromList = postFilesFromList(joinpath(path, directory))
    files = postedFilesFromList[1]
    filesInfo = postedFilesFromList[2]

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

  
  metadataUrl = joinpath(apiurl, "datas")
   
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

function addFileToData(dataIdentifier, file)
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