import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState

    @State private var currentStep = 0
    @State private var draftName = ""
    @State private var selections: [String: String] = [:]
    @State private var multiSelections: [String: Set<String>] = [:]

    /// Flow matches onboarding spec: loader → personalization → Pain–Gap–Truth → … → first task → save → paywall.
    private let totalSteps = 31

    var body: some View {
        ZStack {
            AppBackgroundView(background: .plain)
            OnboardingBackdrop()

            VStack(spacing: 0) {
                progressHeader

                ZStack {
                    screenView(for: currentStep)
                        .id(currentStep)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.spring(response: 0.48, dampingFraction: 0.88), value: currentStep)
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Live the Word")
                    .font(.system(.title3, design: .serif, weight: .regular))
                    .foregroundStyle(appState.palette.primaryText.opacity(0.86))

                Spacer()

                Text("\(currentStep + 1)/\(totalSteps)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(appState.palette.secondaryText)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(appState.palette.border.opacity(0.35))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [appState.palette.headerAccent, appState.palette.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressValue)
                }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var progressValue: CGFloat {
        CGFloat(currentStep + 1) / CGFloat(totalSteps)
    }

    @ViewBuilder
    private func screenView(for step: Int) -> some View {
        // Steps follow onboarding doc: screen numbers in comments are 1-based from the spec.
        switch step {
        case 0: // 1 — Loader
            splashScreen(stepKey: step)
        case 1: // 2 — Name
            nameScreen(stepKey: step)
        case 2: // 3 — Thanks (Continue only)
            messageScreen(
                stepKey: step,
                eyebrow: "Hey \(displayName).",
                title: nil,
                subtitle: nil,
                card: {
                    OnboardingHeroCard {
                        Text("Thanks for trusting us on your journey towards God!! Let's try to understand your life a little bit better.")
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)
                            .lineSpacing(4)
                    }
                },
                footer: nil,
                buttonTitle: "Continue"
            )
        case 3: // 4 — Read frequency
            choiceScreen(
                stepKey: step,
                title: "How often do you read the Bible?",
                subtitle: nil,
                introCard: nil,
                options: ["Every day", "A few times a week", "Occasionally", "Rarely"],
                selectionKey: "read_frequency"
            )
        case 4: // 5 — Pain
            messageScreen(
                stepKey: step,
                eyebrow: "\(displayName) — Have you ever felt this?",
                title: nil,
                subtitle: nil,
                card: {
                    VStack(spacing: 20) {
                        OnboardingHeroCard {
                            Text("You've read the Bible\nyou've understood\n\nBut somehow,\nit still feels like something is missing.\n\nLike you could be doing more.\nLiving it more.")
                                .font(.title3.weight(.medium))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(appState.palette.primaryText)
                                .lineSpacing(4)
                        }

                        OnboardingQuoteCard(
                            quote: "\"Do not merely listen to the word… and so deceive yourselves. Do what it says.\"",
                            reference: "James 1:22",
                            palette: appState.palette
                        )
                    }
                },
                footer: nil,
                buttonTitle: "Yes I Have"
            )
        case 5: // 6 — Core proposition
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: "Don't just read the Word. Live it.",
                subtitle: nil,
                card: {
                    OnboardingHeroCard {
                        Text("Live the Word helps you live the Word of God.")
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)

                        Text("One small action a day based on bible verses…\ncan change who you become.")
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.secondaryText)

                        Text("Every good deed is a step closer to God.")
                            .font(.system(.body, design: .serif, weight: .regular))
                            .italic()
                            .foregroundStyle(appState.palette.secondaryText)
                    }
                },
                footer: nil,
                buttonTitle: "Start My First Step"
            )
        case 6: // 7 — Act on what you read
            choiceScreen(
                stepKey: step,
                title: "Let's Try to Be Honest here …",
                subtitle: "How often do you actually act on what you read in the Bible?",
                introCard: nil,
                options: ["Almost always", "Sometimes", "Rarely", "I don't"],
                selectionKey: "act_frequency"
            )
        case 7: // 8 — After you read
            choiceScreen(
                stepKey: step,
                title: "After you read…",
                subtitle: "What usually happens?",
                introCard: nil,
                options: [
                    "I think about it and move on",
                    "I feel inspired, but don't act",
                    "I forget it later",
                    "I try to apply it"
                ],
                selectionKey: "after_reading"
            )
        case 8: // 9 — Bible given for
            choiceScreen(
                stepKey: step,
                title: "What do you feel the Bible was given for?",
                subtitle: nil,
                introCard: nil,
                options: ["To read and understand", "To guide how we live", "To find comfort", "Not sure"],
                selectionKey: "bible_purpose"
            )
        case 9: // 10 — Gap
            choiceScreen(
                stepKey: step,
                title: "\(displayName) — Let's Be honest…",
                subtitle: "Do you feel like you could be living it more?",
                introCard: nil,
                options: [
                    "Yes - I want more than this",
                    "I think about it sometimes",
                    "I'm not sure yet"
                ],
                selectionKey: "could_live_more"
            )
        case 10: // 11 — Emotional reframe
            notAloneMessageScreen(stepKey: step)
        case 11: // 12 — Reveal
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: nil,
                subtitle: nil,
                card: {
                    OnboardingHeroCard {
                        Text("It wasn't just meant to be read.")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(appState.palette.primaryText)

                        Text("It was meant to be lived—")
                            .font(.system(.title, design: .serif, weight: .semibold))
                            .foregroundStyle(appState.palette.primaryText)

                        Text("every day.\nin your actions,\nin your decisions,\nin your life.")
                            .font(.title2.weight(.regular))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.secondaryText)
                    }
                },
                footer: nil,
                buttonTitle: "Continue"
            )
        case 12: // 13 — Truth drop
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: nil,
                subtitle: nil,
                card: {
                    OnboardingHeroCard {
                        Text("Faith is trainable! If you have the right guidance")
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)

                        Text("You practice it everyday and it comes naturally to you")
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.secondaryText)

                        Text("Life changes\nwhen you act,\nnot just understand.")
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)

                        Text("Faith isn't just something you feel. It's something you live - daily.")
                            .font(.system(.body, design: .serif, weight: .regular))
                            .italic()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.secondaryText)
                    }
                },
                footer: nil,
                buttonTitle: "Train my faith"
            )
        case 13: // 14 — Value expansion
            choiceScreen(
                stepKey: step,
                title: "What do you think would change in your life once you start to live the Bible?",
                subtitle: nil,
                introCard: nil,
                options: ["Better relationships", "Peace", "Self-control", "Purpose", "All of the above"],
                selectionKey: "life_change"
            )
        case 14: // 15 — Problem
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: nil,
                subtitle: nil,
                card: {
                    OnboardingHeroCard {
                        Text("But here's the problem…")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(appState.palette.primaryText)

                        Text("Most people don't know\nhow to actually live it.")
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)

                        Text("So it stays as an intention -\nnot action.")
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.secondaryText)
                    }
                },
                footer: nil,
                buttonTitle: "Continue"
            )
        case 15: // 16 — Friction (multi-select)
            multiSelectScreen(
                stepKey: step,
                title: "What's stopping you from acting daily?",
                subtitle: nil,
                options: [
                    "I don't know what to do",
                    "I'm not consistent",
                    "I forget",
                    "I overthink"
                ],
                selectionKey: "daily_barriers"
            )
        case 16: // 17 — Solution
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: "What if every verse\ncame with something simple to do?",
                subtitle: nil,
                card: {
                    OnboardingHeroCard(alignment: .leading) {
                        Text("Simple actions.")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(appState.palette.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("That help you:")
                            .font(.headline)
                            .foregroundStyle(appState.palette.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("• Grow closer to God")
                            Text("• Become a better person")
                            Text("• Live with intention")
                        }
                        .font(.title3.weight(.medium))
                        .foregroundStyle(appState.palette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                },
                footer: "Something you can apply\nin your day.",
                buttonTitle: "Show me"
            )
        case 17: // 18 — How it works
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: "How this works — Live the Word provides —",
                subtitle: nil,
                card: {
                    OnboardingInfoListCard(
                        title: nil,
                        items: [
                            "A short Bible verse to (read/pray)",
                            "Get one simple task from it",
                            "Apply it in your day",
                            "Build your streak"
                        ],
                        palette: appState.palette,
                        symbols: ["book.closed", "sparkles", "target", "flame"]
                    )
                },
                footer: "Just a few minutes.\nBut real change.",
                buttonTitle: "Build my path"
            )
        case 18: // 19 — Denomination
            choiceScreen(
                stepKey: step,
                title: nil,
                subtitle: "Different traditions follow the same Word\nin slightly different ways.\n\nTo guide you better…\ntell us what you align with:",
                introCard: nil,
                options: ["Catholic", "Protestant", "Orthodox", "Others", "Not sure / Prefer not to say"],
                selectionKey: "tradition"
            )
        case 19: // 20 — Response
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: nil,
                subtitle: nil,
                card: {
                    OnboardingHeroCard {
                        Text("Got it.")
                            .font(.system(.title, design: .serif, weight: .semibold))
                            .foregroundStyle(appState.palette.primaryText)

                        Text("We'll guide you in a way\nthat feels natural to your journey.")
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.secondaryText)
                    }
                },
                footer: nil,
                buttonTitle: "Continue"
            )
        case 20: // 21 — Identity
            choiceScreen(
                stepKey: step,
                title: "What do you want to grow in?",
                subtitle: nil,
                introCard: nil,
                options: ["Faith", "Discipline", "Kindness", "Purpose", "All of the above"],
                selectionKey: "growth"
            )
        case 21: // 22 — Commitment
            choiceScreen(
                stepKey: step,
                title: nil,
                subtitle: nil,
                introCard: {
                    AnyView(OnboardingHeroCard {
                        Text("This isn't about reading more.")
                            .font(.subheadline)
                            .foregroundStyle(appState.palette.secondaryText)

                        Text("Transform into someone\nwho lives the Word.")
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)

                        Text("Can you show up for 2 minutes daily to live it?")
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)
                    })
                },
                options: ["Yes - I commit to this", "I'll show up when I can"],
                selectionKey: "commitment"
            )
        case 22: // 23 — Daily reminder
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: nil,
                subtitle: nil,
                card: {
                    OnboardingHeroCard {
                        Text("It's not about doing more -")
                            .font(.title2.weight(.regular))
                            .foregroundStyle(appState.palette.primaryText)

                        Text("It's about showing up daily.")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(appState.palette.primaryText)

                        Text("A quick daily reminder\nhelps you stay on track.")
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.secondaryText)
                    }
                },
                footer: nil,
                buttonTitle: "Set my daily reminder",
                buttonIcon: "calendar"
            )
        case 23: // 24 — Reinforcement
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: nil,
                subtitle: nil,
                card: {
                    OnboardingHeroCard {
                        Text("Thanks for trusting us on your journey towards God")
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.secondaryText)

                        Text("You've already taken a step\nmost people don't.\n\nAnd that's where\nreal change begins.")
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)
                            .lineSpacing(4)
                    }
                },
                footer: nil,
                buttonTitle: "Lets go"
            )
        case 24: // 25 — Building loader
            loadingScreen(stepKey: step)
        case 25: // 26 — Congratulations
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: "Congratulations! Your journey is ready.",
                subtitle: "Start living the Word. Beginning today.",
                card: {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("This is a simple, structured path\nto grow closer to God -\nBy living it—\none small action at a time.")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(appState.palette.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        OnboardingInfoListCard(
                            title: "What you unlock:",
                            items: [
                                "Daily Bible-based tasks",
                                "Simple, guided actions",
                                "Streak system for consistency",
                                "Real-life transformation"
                            ],
                            palette: appState.palette
                        )
                    }
                },
                footer: nil,
                buttonTitle: "Start My Journey",
                topIcon: "sparkles"
            )
        case 26: // 27 — First step ready
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: "Your first step is ready.",
                subtitle: nil,
                card: {
                    OnboardingIconMoment(symbol: "target", palette: appState.palette)
                },
                footer: nil,
                buttonTitle: "Start My First Task"
            )
        case 27: // Day 1 first task (canonical: same DB task all users get as completed after onboarding)
            messageScreen(
                stepKey: step,
                eyebrow: nil,
                title: FirstOnboardingTask.taskTitle,
                subtitle: nil,
                card: {
                    OnboardingTaskPreviewCard(
                        verse: FirstOnboardingTask.verseQuote,
                        reference: FirstOnboardingTask.verseReference,
                        bulletTitle: "Task:",
                        bullets: [
                            FirstOnboardingTask.taskDescription
                        ],
                        palette: appState.palette
                    )
                },
                footer: nil,
                buttonTitle: "Mark as Complete"
            )
        case 28: // Completion
            celebrationScreen(stepKey: step)
        case 29: // 28 — Save journey
            authScreen(stepKey: step)
        case 30: // 29 — Paywall (placeholder)
            paywallScreen(stepKey: step)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func notAloneMessageScreen(stepKey: Int) -> some View {
        messageScreen(
            stepKey: stepKey,
            eyebrow: nil,
            title: "You are not alone here",
            subtitle: nil,
            card: {
                VStack(spacing: 18) {
                    OnboardingHeroCard {
                        Text("That feeling...\nisn't guilt.\n\nIt's a reminder\nthat you're meant for more.")
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(appState.palette.primaryText)
                            .lineSpacing(4)
                    }

                    OnboardingQuoteCard(
                        quote: "Even Apostle Paul struggled with doing what's right.",
                        reference: nil,
                        palette: appState.palette
                    )
                }
            },
            footer: nil,
            buttonTitle: "Continue"
        )
    }

    private var displayName: String {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Friend" : trimmed
    }

    private func advance() {
        if currentStep >= totalSteps - 1 {
            Task { @MainActor in
                await appState.completeOnboarding(name: displayName)
            }
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                currentStep += 1
            }
        }
    }

    private func select(_ option: String, key: String, completesFlow: Bool = false) {
        selections[key] = option
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            if completesFlow {
                await appState.completeOnboarding(name: displayName)
            } else {
                advance()
            }
        }
    }

    private func choiceScreen(
        stepKey: Int,
        title: String?,
        subtitle: String?,
        introCard: (() -> AnyView)?,
        options: [String],
        selectionKey: String,
        completesFlow: Bool = false
    ) -> some View {
        OnboardingChoiceScreen(
            stepKey: stepKey,
            title: title,
            subtitle: subtitle,
            introCard: introCard,
            options: options,
            selectedOption: selections[selectionKey],
            palette: appState.palette
        ) { option in
            select(option, key: selectionKey, completesFlow: completesFlow)
        }
    }

    private func multiSelectScreen(
        stepKey: Int,
        title: String?,
        subtitle: String?,
        options: [String],
        selectionKey: String
    ) -> some View {
        OnboardingMultiSelectScreen(
            stepKey: stepKey,
            title: title,
            subtitle: subtitle,
            options: options,
            selectedOptions: multiSelections[selectionKey] ?? [],
            palette: appState.palette,
            onToggle: { option in
                var set = multiSelections[selectionKey] ?? []
                if set.contains(option) {
                    set.remove(option)
                } else {
                    set.insert(option)
                }
                multiSelections[selectionKey] = set
            },
            onContinue: advance
        )
    }

    private func paywallScreen(stepKey: Int) -> some View {
        messageScreen(
            stepKey: stepKey,
            eyebrow: nil,
            title: "Go deeper with Live the Word",
            subtitle: nil,
            card: {
                OnboardingHeroCard {
                    Text("Paywall placeholder — pricing and plans TBD.")
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(appState.palette.secondaryText)
                }
            },
            footer: nil,
            buttonTitle: "Continue"
        )
    }

    private func messageScreen<Card: View>(
        stepKey: Int,
        eyebrow: String?,
        title: String?,
        subtitle: String?,
        card: @escaping () -> Card,
        footer: String?,
        buttonTitle: String,
        buttonIcon: String? = nil,
        topIcon: String? = nil
    ) -> some View {
        OnboardingMessageScreen(
            stepKey: stepKey,
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            footer: footer,
            buttonTitle: buttonTitle,
            buttonIcon: buttonIcon,
            topIcon: topIcon,
            palette: appState.palette,
            card: { AnyView(card()) },
            onContinue: advance
        )
    }

    private func nameScreen(stepKey: Int) -> some View {
        OnboardingNameScreen(
            stepKey: stepKey,
            palette: appState.palette,
            name: $draftName,
            onContinue: advance
        )
    }

    private func loadingScreen(stepKey: Int) -> some View {
        OnboardingLoadingScreen(
            stepKey: stepKey,
            palette: appState.palette,
            items: [
                "Understanding your spiritual goals",
                "Aligning your journey with God's Word",
                "Personalising actions for your daily life",
                "Selecting/Analysing your verse-based tasks",
                "Preparing your 30-day growth journey"
            ],
            onFinished: advance
        )
    }

    private func celebrationScreen(stepKey: Int) -> some View {
        OnboardingCelebrationScreen(
            stepKey: stepKey,
            palette: appState.palette,
            onContinue: advance
        )
    }

    private func splashScreen(stepKey: Int) -> some View {
        OnboardingSplashScreen(
            stepKey: stepKey,
            palette: appState.palette,
            onFinished: advance
        )
    }

    private func authScreen(stepKey: Int) -> some View {
        OnboardingAuthScreen(
            stepKey: stepKey,
            palette: appState.palette,
            onContinue: advance
        )
    }
}

private struct OnboardingBackdrop: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [.white.opacity(0.65), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 220, height: 220)
                .blur(radius: 32)
                .offset(x: 140, y: -260)

            RoundedRectangle(cornerRadius: 46, style: .continuous)
                .fill(Color.white.opacity(0.16))
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(12))
                .blur(radius: 12)
                .offset(x: -180, y: 320)
        }
        .allowsHitTesting(false)
    }
}

private struct OnboardingChoiceScreen: View {
    let stepKey: Int
    let title: String?
    let subtitle: String?
    let introCard: (() -> AnyView)?
    let options: [String]
    let selectedOption: String?
    let palette: AppThemePalette
    let onSelect: (String) -> Void

    @State private var showHeader = false
    @State private var visibleOptions = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 24)

                if let introCard {
                    introCard()
                        .opacity(showHeader ? 1 : 0)
                        .offset(y: showHeader ? 0 : 22)
                }

                if title != nil || subtitle != nil {
                    CardContainer(palette: palette) {
                        VStack(alignment: .leading, spacing: 16) {
                            if let title {
                                Text(title)
                                    .font(.system(.title2, design: .serif, weight: .semibold))
                                    .foregroundStyle(palette.primaryText)
                            }

                            if let subtitle {
                                Text(subtitle)
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(palette.secondaryText)
                                    .lineSpacing(4)
                            }

                            VStack(spacing: 12) {
                                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                                    OnboardingOptionButton(
                                        title: option,
                                        isSelected: selectedOption == option,
                                        palette: palette,
                                        action: { onSelect(option) }
                                    )
                                    .opacity(visibleOptions > index ? 1 : 0)
                                    .offset(y: visibleOptions > index ? 0 : 14)
                                }
                            }
                        }
                    }
                    .opacity(showHeader ? 1 : 0)
                    .offset(y: showHeader ? 0 : 22)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            OnboardingOptionButton(
                                title: option,
                                isSelected: selectedOption == option,
                                palette: palette,
                                action: { onSelect(option) }
                            )
                            .opacity(visibleOptions > index ? 1 : 0)
                            .offset(y: visibleOptions > index ? 0 : 14)
                        }
                    }
                }

                Spacer(minLength: 36)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .task(id: stepKey) {
            showHeader = false
            visibleOptions = 0
            withAnimation(.easeOut(duration: 0.42)) {
                showHeader = true
            }
            for index in options.indices {
                try? await Task.sleep(for: .milliseconds(90))
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                    visibleOptions = index + 1
                }
            }
        }
    }
}

private struct OnboardingMultiSelectScreen: View {
    let stepKey: Int
    let title: String?
    let subtitle: String?
    let options: [String]
    let selectedOptions: Set<String>
    let palette: AppThemePalette
    let onToggle: (String) -> Void
    let onContinue: () -> Void

    @State private var showHeader = false
    @State private var visibleOptions = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 24)

                if title != nil || subtitle != nil {
                    CardContainer(palette: palette) {
                        VStack(alignment: .leading, spacing: 16) {
                            if let title {
                                Text(title)
                                    .font(.system(.title2, design: .serif, weight: .semibold))
                                    .foregroundStyle(palette.primaryText)
                            }

                            if let subtitle {
                                Text(subtitle)
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(palette.secondaryText)
                                    .lineSpacing(4)
                            }

                            VStack(spacing: 12) {
                                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                                    OnboardingOptionButton(
                                        title: option,
                                        isSelected: selectedOptions.contains(option),
                                        palette: palette,
                                        action: { onToggle(option) }
                                    )
                                    .opacity(visibleOptions > index ? 1 : 0)
                                    .offset(y: visibleOptions > index ? 0 : 14)
                                }
                            }
                        }
                    }
                    .opacity(showHeader ? 1 : 0)
                    .offset(y: showHeader ? 0 : 22)
                }

                OnboardingPrimaryButton(
                    title: "Continue",
                    systemImage: nil,
                    palette: palette,
                    action: onContinue
                )
                .opacity(showHeader ? 1 : 0)

                Spacer(minLength: 36)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .task(id: stepKey) {
            showHeader = false
            visibleOptions = 0
            withAnimation(.easeOut(duration: 0.42)) {
                showHeader = true
            }
            for index in options.indices {
                try? await Task.sleep(for: .milliseconds(90))
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                    visibleOptions = index + 1
                }
            }
        }
    }
}

private struct OnboardingMessageScreen: View {
    let stepKey: Int
    let eyebrow: String?
    let title: String?
    let subtitle: String?
    let footer: String?
    let buttonTitle: String
    let buttonIcon: String?
    let topIcon: String?
    let palette: AppThemePalette
    let card: () -> AnyView
    let onContinue: () -> Void

    @State private var revealCount = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Spacer(minLength: 36)

                if let topIcon {
                    OnboardingIconMoment(symbol: topIcon, palette: palette)
                        .opacity(revealCount > 0 ? 1 : 0)
                        .scaleEffect(revealCount > 0 ? 1 : 0.82)
                }

                VStack(spacing: 10) {
                    if let eyebrow {
                        Text(eyebrow)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.secondaryText)
                    }

                    if let title {
                        Text(title)
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(palette.primaryText)
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(palette.secondaryText)
                    }
                }
                .opacity(revealCount > 0 ? 1 : 0)
                .offset(y: revealCount > 0 ? 0 : 20)

                card()
                    .opacity(revealCount > 1 ? 1 : 0)
                    .offset(y: revealCount > 1 ? 0 : 24)

                if let footer {
                    Text(footer)
                        .font(.system(.body, design: .serif, weight: .regular))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(palette.secondaryText)
                        .opacity(revealCount > 2 ? 1 : 0)
                        .offset(y: revealCount > 2 ? 0 : 16)
                }

                OnboardingPrimaryButton(
                    title: buttonTitle,
                    systemImage: buttonIcon,
                    palette: palette,
                    action: onContinue
                )
                .opacity(revealCount > 2 ? 1 : 0)
                .offset(y: revealCount > 2 ? 0 : 20)

                Spacer(minLength: 34)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
        }
        .task(id: stepKey) {
            revealCount = 0
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.easeOut(duration: 0.38)) {
                revealCount = 1
            }
            try? await Task.sleep(for: .milliseconds(130))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                revealCount = 2
            }
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.easeOut(duration: 0.32)) {
                revealCount = 3
            }
        }
    }
}

private struct OnboardingNameScreen: View {
    let stepKey: Int
    let palette: AppThemePalette
    @Binding var name: String
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 10) {
                Text("Let's make this journey more personal")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(palette.primaryText)

                Text("What should we call you?")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(palette.secondaryText)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            VStack(spacing: 16) {
                TextField("Your name", text: $name)
                    .padding(.horizontal, 20)
                    .frame(height: 58)
                    .background(palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isFocused ? palette.accent : palette.border.opacity(0.7), lineWidth: 1.2)
                    )
                    .shadow(color: palette.shadow.opacity(0.55), radius: 14, x: 0, y: 8)
                    .focused($isFocused)
                    .autocorrectionDisabled()

                OnboardingPrimaryButton(
                    title: "Continue",
                    systemImage: nil,
                    palette: palette,
                    isDisabled: trimmedName.isEmpty,
                    action: onContinue
                )
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 28)

            Spacer()
        }
        .padding(.horizontal, 24)
        .task(id: stepKey) {
            showContent = false
            withAnimation(.easeOut(duration: 0.42)) {
                showContent = true
            }
            try? await Task.sleep(for: .milliseconds(250))
            isFocused = true
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct OnboardingLoadingScreen: View {
    let stepKey: Int
    let palette: AppThemePalette
    let items: [String]
    let onFinished: () -> Void

    @State private var completedCount = 0
    @State private var showTitle = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            VStack(spacing: 10) {
                Text("Almost there")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.6)
                    .foregroundStyle(palette.secondaryText)

                Text("Building your personal journey...")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.primaryText)
            }
            .opacity(showTitle ? 1 : 0)
            .offset(y: showTitle ? 0 : 20)

            VStack(spacing: 14) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(index < completedCount ? palette.headerAccent : palette.card)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: index < completedCount ? "checkmark" : "circle.dashed")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(index < completedCount ? .white : palette.secondaryText)
                            }

                        Text(item)
                            .font(.headline)
                            .foregroundStyle(palette.primaryText)

                        Spacer()
                    }
                    .padding(18)
                    .background(palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(index < completedCount ? palette.headerAccent.opacity(0.55) : palette.border.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: palette.shadow.opacity(0.45), radius: 12, x: 0, y: 6)
                    .opacity(showTitle ? 1 : 0)
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 30)
        }
        .padding(.horizontal, 24)
        .task(id: stepKey) {
            completedCount = 0
            showTitle = false
            withAnimation(.easeOut(duration: 0.4)) {
                showTitle = true
            }
            for index in items.indices {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                    completedCount = index + 1
                }
            }
            try? await Task.sleep(for: .milliseconds(450))
            onFinished()
        }
    }
}

private struct OnboardingCelebrationScreen: View {
    let stepKey: Int
    let palette: AppThemePalette
    let onContinue: () -> Void

    @State private var revealCount = 0

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(palette.headerAccent)
                    .frame(width: 112, height: 112)
                    .shadow(color: palette.shadow.opacity(0.5), radius: 18, x: 0, y: 10)

                Image(systemName: "checkmark")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(revealCount > 0 ? 1 : 0.8)
            .opacity(revealCount > 0 ? 1 : 0)

            VStack(spacing: 8) {
                Text("You didn't just read today.")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(palette.secondaryText)

                Text("You lived it.")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(palette.primaryText)
            }
            .opacity(revealCount > 0 ? 1 : 0)

            CardContainer(palette: palette) {
                VStack(spacing: 8) {
                    Text("Congratulations!! — Streak Started: Day 1")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(palette.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .opacity(revealCount > 1 ? 1 : 0)

            Text("Tomorrow,\nyou'll be one step further.")
                .font(.system(.body, design: .serif, weight: .regular))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.secondaryText)
                .opacity(revealCount > 1 ? 1 : 0)

            OnboardingPrimaryButton(
                title: "Continue",
                systemImage: nil,
                palette: palette,
                action: onContinue
            )
            .opacity(revealCount > 2 ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, 24)
        .task(id: stepKey) {
            revealCount = 0
            withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
                revealCount = 1
            }
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.3)) {
                revealCount = 2
            }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeOut(duration: 0.3)) {
                revealCount = 3
            }
        }
    }
}

private struct OnboardingSplashScreen: View {
    let stepKey: Int
    let palette: AppThemePalette
    let onFinished: () -> Void

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(palette.headerAccent)
                .frame(width: 98, height: 98)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: palette.shadow.opacity(0.45), radius: 20, x: 0, y: 10)
                .scaleEffect(showContent ? 1 : 0.78)
                .opacity(showContent ? 1 : 0)

            VStack(spacing: 8) {
                Text("Live the Word")
                    .font(.system(size: 42, weight: .regular, design: .serif))
                    .foregroundStyle(palette.primaryText)

                Text("Every good deed is a step closer to God.")
                    .font(.system(.title3, design: .serif, weight: .regular))
                    .italic()
                    .foregroundStyle(palette.secondaryText)

                Text("By Christians, for Christians")
                    .font(.headline)
                    .foregroundStyle(palette.secondaryText.opacity(0.85))
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 16)

            Spacer()
        }
        .padding(.horizontal, 24)
        .task(id: stepKey) {
            showContent = false
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                showContent = true
            }
            try? await Task.sleep(for: .seconds(2))
            onFinished()
        }
    }
}

private struct OnboardingAuthScreen: View {
    @EnvironmentObject private var appState: AppState

    let stepKey: Int
    let palette: AppThemePalette
    let onContinue: () -> Void

    @State private var showContent = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 12)

                VStack(spacing: 10) {
                    Text("Save my journey")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(palette.primaryText)
                        .multilineTextAlignment(.center)

                    if appState.isSupabaseSessionActive {
                        Text("You’re signed in. Your progress will be saved to this account when you finish onboarding.")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(palette.secondaryText)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Sign in with your username or email and password. If you use a username only, we create a private sign-in email for your account.")
                            .font(.subheadline)
                            .foregroundStyle(palette.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(showContent ? 1 : 0)

                if appState.isSupabaseSessionActive {
                    Button {
                        onContinue()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(palette.headerAccent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .opacity(showContent ? 1 : 0)
                    .padding(.top, 8)
                } else {
                    EmailPasswordAuthForm(appState: appState, palette: palette, onSuccess: onContinue)
                        .opacity(showContent ? 1 : 0)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .task(id: stepKey) {
            showContent = false
            withAnimation(.easeOut(duration: 0.42)) {
                showContent = true
            }
        }
    }
}

private struct OnboardingHeroCard<Content: View>: View {
    var alignment: HorizontalAlignment = .center
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: alignment, spacing: 16) {
            content
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 12)
    }
}

private struct OnboardingTaskPreviewCard: View {
    let verse: String
    let reference: String
    let bulletTitle: String
    let bullets: [String]
    let palette: AppThemePalette

    var body: some View {
        CardContainer(palette: palette) {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingQuoteCard(
                    quote: verse,
                    reference: reference,
                    palette: palette
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(bulletTitle.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(palette.secondaryText)

                    ForEach(bullets, id: \.self) { bullet in
                        Text("• \(bullet)")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(palette.primaryText)
                    }
                }
            }
        }
    }
}

private struct OnboardingQuoteCard: View {
    let quote: String
    let reference: String?
    let palette: AppThemePalette

    var body: some View {
        VStack(spacing: 12) {
            Text(quote)
                .font(.system(.title3, design: .serif, weight: .regular))
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.primaryText)

            if let reference {
                Text("— \(reference)")
                    .font(.headline)
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(palette.card.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(palette.border.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct OnboardingInfoListCard: View {
    let title: String?
    let items: [String]
    let palette: AppThemePalette
    var symbols: [String] = []

    var body: some View {
        CardContainer(palette: palette) {
            VStack(alignment: .leading, spacing: 16) {
                if let title {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(palette.secondaryText)
                }

                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        if symbols.indices.contains(index) {
                            Image(systemName: symbols[index])
                                .frame(width: 24)
                                .foregroundStyle(palette.accent)
                        } else {
                            Circle()
                                .fill(palette.border)
                                .frame(width: 7, height: 7)
                        }

                        Text(item)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(palette.primaryText)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct OnboardingIconMoment: View {
    let symbol: String
    let palette: AppThemePalette

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(palette.headerAccent)
            .frame(width: 96, height: 96)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: palette.shadow.opacity(0.45), radius: 18, x: 0, y: 10)
    }
}

private struct OnboardingOptionButton: View {
    let title: String
    let isSelected: Bool
    let palette: AppThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(palette.primaryText)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 58)
            .background(isSelected ? palette.canvas.opacity(0.85) : palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? palette.accent.opacity(0.72) : palette.border.opacity(0.74), lineWidth: 1.2)
            )
            .shadow(color: palette.shadow.opacity(isSelected ? 0.38 : 0.18), radius: isSelected ? 16 : 10, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct OnboardingPrimaryButton: View {
    let title: String
    let systemImage: String?
    let palette: AppThemePalette
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .font(.title3.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(isDisabled ? 0.8 : 1))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: isDisabled
                        ? [palette.headerAccent.opacity(0.55), palette.headerAccent.opacity(0.45)]
                        : [palette.headerAccent, palette.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: palette.shadow.opacity(isDisabled ? 0.12 : 0.34), radius: 18, x: 0, y: 10)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}

#Preview {
    AppStatePreviewRoot { _ in
        OnboardingFlowView()
    }
}
