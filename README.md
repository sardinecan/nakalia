# nakala
Some scripts to use with Nakala's API ([https://api.nakala.fr/doc](https://api.nakala.fr/doc))

Here is the link for the test API where you can find public credentials to give a try: [https://test.nakala.fr/](https://test.nakala.fr/).

## prerequisite
- Julia Lang [https://julialang.org/](https://julialang.org/)
- create a `credentials.csv` file at the root of this repository with two columns `user` and `apikey`. Example with a public key:
  
| user    | apikey |
| -------- | ------- |
| tnakala  | 01234567-89ab-cdef-0123-456789abcdef  |

## repo map
```
nakala
├── API_nakala.jl // Generic script to get informations about user, etc. (should be a notebook)
├── uploadDatas/ // to upload data to nakala (data ≠ file: one folder = one data)
│   ├── listFile.jl // this script lists files contained in a folder
│   ├── metadata.csv // the metadata of the data
│   └── uploadDatas.jl // the file to execute to upload data
├── tmp/ // temporary files, test, etc.
└── README.md
```
