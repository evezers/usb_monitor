library ieee;
    use ieee.std_logic_1164.all;

entity fsm_control is
    port (
        clk    : in    std_logic;
        reset  : in    std_logic;
        enable : in    std_logic;

        -- fsm_ulpi_registers
        o_fsm_ulpi_registers_enable : out   std_logic;
        o_register_request          : out   std_logic;
        o_register_address          : out   std_logic_vector(7 downto 0);
        o_register_data             : out   std_logic_vector(7 downto 0);
        i_register_busy : in    std_logic;

        ulpi_config_finished : in    std_logic
    );
end entity fsm_control;

architecture rtl of fsm_control is

    signal r_fsm_ulpi_registers_enable : std_logic;
    signal r_register_request          : std_logic;
    signal r_register_address          : std_logic_vector(7 downto 0);
    signal r_register_data             : std_logic_vector(7 downto 0);

    type fsm_control_state_type is (
        ulpi_config_state,
        usb_connect_state,
        usb_config_state,
        usb_idle_state,
        usb_disconnect
    );

    signal state : fsm_control_state_type;

begin

    o_fsm_ulpi_registers_enable <= r_fsm_ulpi_registers_enable;
    o_register_request          <= r_register_request;
    o_register_address          <= r_register_address;
    o_register_data             <= r_register_data;

    process (enable, clk, reset) is
    begin

        if (enable = '0') then
        -- o_data <= (others => 'Z');
        elsif (reset = '1') then
            state <= ulpi_config_state;

            -- data_head_r <= (others => '0');
            r_register_data             <= (others => '0');
            r_register_address          <= (others => '0');
            r_register_request          <= '0';
            r_fsm_ulpi_registers_enable <= '0';
        elsif (rising_edge(clk)) then

            case state is

                when ulpi_config_state =>

                    if (i_register_busy = '0') then
                        state <= usb_connect_state;
                    else
                        state <= state;
                    end if;

                when usb_connect_state =>

                    if (ulpi_config_finished = '1') then
                        state <= usb_config_state;
                    else
                        state <= state;
                    end if;

                when usb_config_state =>

                    if (ulpi_config_finished = '1') then
                        state <= usb_idle_state;
                    else
                        state <= state;
                    end if;

                when usb_idle_state =>

                    if (ulpi_config_finished = '1') then
                        state <= usb_disconnect;
                    else
                        state <= state;
                    end if;

                when usb_disconnect =>

                    if (ulpi_config_finished = '1') then
                        state <= usb_connect_state;
                    else
                        state <= state;
                    end if;

            end case;

        end if;

    end process;

    process (state) is
    begin

        case state is

            when ulpi_config_state =>

                o_register_address          <= b"1000_1010";
                o_register_data             <= b"0000_0000";
                o_register_request          <= '1';
                o_fsm_ulpi_registers_enable <= '1';

            when usb_connect_state =>

                o_register_request          <= '0';
                o_fsm_ulpi_registers_enable <= '0';

            when usb_config_state =>

                if (ulpi_config_finished = '1') then
                    state <= usb_idle_state;
                else
                    state <= state;
                end if;

            when usb_idle_state =>

                if (ulpi_config_finished = '1') then
                    state <= usb_disconnect;
                else
                    state <= state;
                end if;

            when usb_disconnect =>

                if (ulpi_config_finished = '1') then
                    state <= usb_connect_state;
                else
                    state <= state;
                end if;

        end case;

    end process;

end architecture rtl;
