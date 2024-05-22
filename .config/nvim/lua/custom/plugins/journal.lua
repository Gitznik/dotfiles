return {
    "jakobkhansen/journal.nvim",
    commit = "56ad4cdc4cdd2e05d4cd4f27ae26317e84387ff6",
    config = function()
        require("journal").setup(
            {
                journal = {
                    entries = {
                        work = {
                            format = 'work/%Y/%m-%B/daily/%d-%A',
                            template = "# Work %A %B %d %Y\n",
                            frequency = { day = 1 },

                            entries = {
                                day = {
                                    format = 'work/%Y/%m-%B/daily/%d-%A',
                                    template = "# Work %A %B %d %Y\n",
                                    frequency = { day = 1 },
                                },
                                week = {
                                    format = 'work/%Y/%m-%B/weekly/week-%W',
                                    template = "# Work Week %W %B %Y\n",
                                    frequency = { day = 7 },
                                    date_modifier = "monday"
                                },
                                quarter = {
                                    -- strftime doesn't supply a quarter variable, so we compute it manually
                                    format = function(date)
                                        local quarter = math.ceil(tonumber(os.date("%m", os.time(date.date))) / 3)
                                        return "work/%Y/quarter/" .. quarter
                                    end,
                                    template = function(date)
                                        local quarter = math.ceil(os.date("%m", os.time(date.date)) / 3)
                                        return "# Work %Y Quarter " .. quarter .. "\n"
                                    end,
                                    frequency = { month = 3 },
                                }
                            }
                        },
                        private = {
                            format = 'private/%Y/%m-%B/daily/%d-%A',
                            template = "# Private %A %B %d %Y\n",
                            frequency = { day = 1 },

                            entries = {
                                day = {
                                    format = 'private/%Y/%m-%B/daily/%d-%A',
                                    template = "# Private %A %B %d %Y\n",
                                    frequency = { day = 1 },
                                },
                                week = {
                                    format = 'private/%Y/%m-%B/weekly/week-%W',
                                    template = "# Private Week %W %B %Y\n",
                                    frequency = { day = 7 },
                                    date_modifier = "monday"
                                },
                            }
                        },
                    }
                }
            }
        )
    end,
}
