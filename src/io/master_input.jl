
function generate_parse(card_info_dsl::String, forward_lookup_map::Dict, length_map_init::Dict)
    
    headers_vec = String[]
    headers_map = Dict{String, Vector{String}}()
    for row in split(card_info_dsl, "\n")
        if length(row) == 0
            continue
        end
        rl = split(row)
        headers_map[rl[1]] = rl[2:end]
        push!(headers_vec, rl[1])
    end
    
    # @path_to_lines
    function _parse(lines; extra_length_map=Dict())
        length_map = deepcopy(length_map_init)
        merge!(length_map, extra_length_map)

        it_lines = Iterators.Stateful(replace(strip(line), "\t"=>" ") for line in lines)

        df_remain = String[]
        comment_remain = String[]

        df_map = Dict{String, DataFrame}()
        
        comment_char_set = Set(('#', 'C'))

        node_list = Any[]
        # for (key, fields) in headers_map
        for key in headers_vec
            fields = headers_map[key]
            if length_map[key] == 0
                df = DataFrame(Matrix{Any}(undef, 0, length(fields)), fields)

                df_map[key] = df
                push!(node_list, df)
                continue
            end
            for line in it_lines
                if length(line) == 0 || line[1] in comment_char_set
                    push!(comment_remain, line)
                    continue
                end
                push!(df_remain, line)
                
                if length(df_remain) == length_map[key]

                    buf = IOBuffer(join(df_remain, "\n"))
                    df = DataFrame(CSV.File(buf, header=false, ignorerepeated=true, delim=" "))
                    @assert size(df, 2) == length(fields)
                    rename!(df, fields)

                    push!(node_list, comment_remain)
                    df_map[key] = df
                    push!(node_list, df)
                    
                    df_remain = String[]
                    comment_remain = String[]
                    
                    if key in keys(forward_lookup_map)
                        for (field, set_cards) in forward_lookup_map[key]
                            value = df[1, field]
                            for set_card in set_cards
                                length_map[set_card] = value
                            end
                        end
                    end
                    break
                end
            end
            # error("Unexpected reaching end of file")
            # println("Unexpected reaching end of file")
        end
        
        @assert length(df_remain) == 0 && length(comment_remain) == 0
        
        """
        # collect trailing comment (if any)
        lines_trailing = collect(it_lines)
        if len(lines_trailing) > 0
            push!(node_list, lines_trailing)
        end
        """

        return node_list, df_map
    end

    return _parse
end


