# Nakalia
Nakala's API with Julia! ([https://api.nakala.fr/doc](https://api.nakala.fr/doc))

Here is the link for the test API where you can find public credentials to give a try: [https://test.nakala.fr/](https://test.nakala.fr/).

## prerequisite
- Julia Lang [https://julialang.org/](https://julialang.org/)
- create a `credentials.csv` file with two columns `user` and `apikey`. Example with a public key for the test API:
  
| user    | apikey |
| -------- | ------- |
| tnakala  | 01234567-89ab-cdef-0123-456789abcdef  |

## repo map
```
nakalia
├── API_nakala.jl // Generic script to get informations about user, etc. (should be a notebook)
├── listFile.jl // this script lists files contained in folders (used to upload data and files)
└── README.md
```
