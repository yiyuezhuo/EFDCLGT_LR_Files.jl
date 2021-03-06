
module _efdc_inp

export efdc_inp
using DataFrames
import ..EFDCLGT_LR_Files: generate_parse, load, save, AbstractFile, name
using DateDataFrames

const card_info_dsl = """
C02  ISRESTI   ISDRY  ISIMTMP  ISIMWQ  ISIMDYE  TEMO  RKDYE  IASWRAD  SWRATNF   REVCHC  DABEDT  TBEDIT HTBED1 HTBED2    KBHM
C03  NTC  NTSPTC  TBEGIN
C04  IC  JC   LVC ISMASK KC ZBRADJ HMIN    HADJ  HDRY  HWET  BELADJ
C05     K        DZC
C06 AHO  AHD  AVO    ABO    AVMN  ABMN  VISMUD AVBCON ZBRWALL
C07 NWSER NASER  NTSER  NQSIJ  NQSER  NQCTL  NQCTLT  NQWR  NQWRSR
C08 IQS  JQS   QSSE NQSMFF NQSERQ NT-  ND-  Qfactor
C09  TEM     DYE
C10 IQCTLU JQCTLU IQCTLD JQCTLD NQCTYP NQCTLQ NQCMUL NQC_U NQC_D BQC_U  BQC_D	CREST	SEEP
C11 IWRU JWRU KWRU IWRD JCWRD KWRD  QWRE NQW_RQ NQWR_U NQWR_D BQWR_U BQWR_D	WD_BEGIN  WD_END
C12 TEMP  DYEC
C13 ISPD NPD  NPDRT   NWPD ISLRPD ILRPD1 ILRPD2 JLRPD1  JLRPD2 IPLRPD
C14   RI   RJ   RK
C15 ISTMSR  MLTMSR  NBTMSR  NSTMSR     NWTMSR
C16 ILTS JLTS  MTSP MTSC MTSA MTSUE MTSUT MTSU MTSQE MTSQ  CLTS
C17   WID IRELH   RAINCVT   EVAPCVT  SOLRCVT  CLDCVT   TASER   TWSER    WSADJ    WNDD    STANAME
"""

const forward_lookup_map = Dict{String, Dict{String, Vector{String}}}(
    "C07"=> Dict(
        "NQSIJ" => ["C08", "C09"],
        "NQCTL" => ["C10"],
        "NQWR" => ["C11", "C12"]
    ),
    "C13" => Dict(
        "NPD" => ["C14"]
    ),
    "C15"=> Dict(
        "MLTMSR"=> ["C16"]
    )
)

const length_map_init = Dict{String, Int}(
    "C02" => 1,
    "C03" => 1,
    "C04" => 1,
    "C05" => 1,
    "C06" => 1,
    "C07" => 1,
    
    "C13" => 1,
    
    "C15" => 1,
    
    "C17" => 1
)

const _parse = generate_parse(card_info_dsl, forward_lookup_map, length_map_init)

struct efdc_inp <: AbstractFile
    node_list::Vector{Union{DataFrame, Vector{String}}}
    _df_map::Dict{String, DataFrame}
end

function Base.getindex(d::efdc_inp, index::String)
    return d._df_map[index]
end

Base.keys(d::efdc_inp) = keys(d._df_map)

function load(io::IO, ::Type{efdc_inp})
    return efdc_inp(_parse(eachline(io))...)
end

function save(io::IO, d::efdc_inp)
    for node in d.node_list
        save(io, node)
        # write(io, "\n")
    end
end

name(::Type{efdc_inp}) = "efdc.inp"

end

using ._efdc_inp
