# Nakalia
Nakala's API with Julia! ([https://api.nakala.fr/doc](https://api.nakala.fr/doc))

Here is the link for the test API where you can find public credentials to give a try: [https://test.nakala.fr/](https://test.nakala.fr/).

## prerequisite
- Julia Lang [https://julialang.org/](https://julialang.org/)
- create a `credentials.csv` file with two columns `user` and `apikey`. Example with a public key for the test API:
  
| user    | apikey |
| -------- | ------- |
| tnakala  | 01234567-89ab-cdef-0123-456789abcdef  |

## Julia Env 
```julia
> git clone https://github.com/sardinecan/nakalia
  Cloning into 'nakalia'...

# With Julia
(@v1.8) pkg> activate nakalia
  Activating project at ~/nakalia

(nakalia) pkg> instantiate
  No Changes to `~/nakalia/Project.toml`
  No Changes to `~/nakalia/Manifest.toml`
```

## repo map
```
nakalia
├── dataToSubmit // data sample (see notebook)
├── filesToUpload // data sample (see notebook)
├── API_nakala.ipynb // a Julia Notebook with examples
├── functions.jl // a library of documented functions to query the Nakala's API
├── Manifest.toml
├── Project.toml
└── README.md
```
